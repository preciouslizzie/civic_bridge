const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const Filter = require('bad-words');
const sharp = require('sharp');
const cron = require('node-cron');

admin.initializeApp();

// Initialize bad words filter
const filter = new Filter();

// Moderation functions
exports.moderateIssue = functions.firestore
  .document('issues/{issueId}')
  .onCreate(async (snap, context) => {
    const issue = snap.data();
    const issueId = context.params.issueId;

    try {
      // Check for inappropriate content
      const isInappropriate = checkContentModeration(issue.title + ' ' + issue.description);

      if (isInappropriate) {
        // Flag for manual review
        await snap.ref.update({
          status: 'flagged',
          moderationNote: 'Content flagged for review',
          flaggedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify moderators
        await notifyModerators('issue_flagged', {
          issueId,
          reason: 'inappropriate_content',
          content: issue.title
        });
      } else {
        // Auto-approve if content is clean
        await snap.ref.update({
          status: 'pending',
          moderatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }

      // Process images if any
      if (issue.images && issue.images.length > 0) {
        await processIssueImages(issueId, issue.images);
      }

    } catch (error) {
      console.error('Error moderating issue:', error);
    }
  });

exports.moderateComment = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();
    const commentId = context.params.commentId;

    try {
      const isInappropriate = checkContentModeration(comment.content);

      if (isInappropriate) {
        await snap.ref.update({
          status: 'flagged',
          moderationNote: 'Comment flagged for review',
          flaggedAt: admin.firestore.FieldValue.serverTimestamp()
        });

        // Notify comment author and moderators
        await notifyUser(comment.userId, 'comment_flagged', {
          commentId,
          reason: 'inappropriate_content'
        });

        await notifyModerators('comment_flagged', {
          commentId,
          reason: 'inappropriate_content',
          content: comment.content.substring(0, 100)
        });
      }

    } catch (error) {
      console.error('Error moderating comment:', error);
    }
  });

// Notification functions
exports.sendIssueStatusNotification = functions.firestore
  .document('issues/{issueId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    const issueId = context.params.issueId;

    // Check if status changed
    if (before.status !== after.status) {
      await notifyUser(after.userId, 'issue_status_changed', {
        issueId,
        oldStatus: before.status,
        newStatus: after.status,
        title: after.title
      });
    }
  });

exports.sendCommentNotification = functions.firestore
  .document('comments/{commentId}')
  .onCreate(async (snap, context) => {
    const comment = snap.data();

    // Notify issue author (if not commenting on own issue)
    const issueRef = admin.firestore().collection('issues').doc(comment.issueId);
    const issue = await issueRef.get();

    if (issue.exists && issue.data().userId !== comment.userId) {
      await notifyUser(issue.data().userId, 'new_comment', {
        issueId: comment.issueId,
        commentId: context.params.commentId,
        commenterName: comment.userName || 'Anonymous',
        content: comment.content.substring(0, 100)
      });
    }
  });

// Vote aggregation function
exports.updateIssueVotes = functions.firestore
  .document('votes/{voteId}')
  .onWrite(async (change, context) => {
    const vote = change.after.exists ? change.after.data() : null;
    const issueId = vote ? vote.issueId : change.before.data().issueId;

    try {
      // Recalculate vote counts
      const votesSnapshot = await admin.firestore()
        .collection('votes')
        .where('issueId', '==', issueId)
        .get();

      let upvotes = 0;
      let downvotes = 0;

      votesSnapshot.forEach(doc => {
        const voteData = doc.data();
        if (voteData.type === 'upvote') upvotes++;
        else if (voteData.type === 'downvote') downvotes++;
      });

      // Update issue with new vote counts
      await admin.firestore().collection('issues').doc(issueId).update({
        upvotes,
        downvotes,
        totalVotes: upvotes - downvotes,
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      });

    } catch (error) {
      console.error('Error updating issue votes:', error);
    }
  });

// Scheduled cleanup functions
exports.cleanupOldTempFiles = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: 'temp/' });

    const twentyFourHoursAgo = Date.now() - (24 * 60 * 60 * 1000);

    for (const file of files) {
      const [metadata] = await file.getMetadata();
      const createdTime = new Date(metadata.timeCreated).getTime();

      if (createdTime < twentyFourHoursAgo) {
        await file.delete();
        console.log(`Deleted old temp file: ${file.name}`);
      }
    }

    return null;
  });

// Analytics functions
exports.updateIssueStats = functions.firestore
  .document('issues/{issueId}')
  .onWrite(async (change, context) => {
    try {
      const statsRef = admin.firestore().collection('stats').doc('issues');

      if (!change.after.exists) {
        // Issue deleted
        await statsRef.update({
          totalIssues: admin.firestore.FieldValue.increment(-1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } else if (!change.before.exists) {
        // Issue created
        await statsRef.update({
          totalIssues: admin.firestore.FieldValue.increment(1),
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      }
    } catch (error) {
      console.error('Error updating issue stats:', error);
    }
  });

// Helper functions
function checkContentModeration(content) {
  // Check for bad words
  if (filter.isProfane(content)) {
    return true;
  }

  // Check for spam patterns
  const spamPatterns = [
    /(.)\1{4,}/, // Repeated characters
    /free\s+money/i,
    /earn\s+money\s+fast/i,
    /click\s+here/i,
    /buy\s+now/i
  ];

  return spamPatterns.some(pattern => pattern.test(content));
}

async function processIssueImages(issueId, imageUrls) {
  const bucket = admin.storage().bucket();

  for (let i = 0; i < imageUrls.length; i++) {
    try {
      const imageUrl = imageUrls[i];
      const fileName = `issues/${issueId}/${i}.jpg`;

      // Download image
      const response = await axios.get(imageUrl, { responseType: 'arraybuffer' });
      const imageBuffer = Buffer.from(response.data);

      // Process image (resize, compress)
      const processedImage = await sharp(imageBuffer)
        .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
        .jpeg({ quality: 80 })
        .toBuffer();

      // Upload processed image
      const file = bucket.file(fileName);
      await file.save(processedImage, {
        metadata: {
          contentType: 'image/jpeg',
          metadata: {
            processed: 'true',
            originalUrl: imageUrl
          }
        }
      });

      // Update issue with processed image URL
      const publicUrl = `https://storage.googleapis.com/${bucket.name}/${fileName}`;
      imageUrls[i] = publicUrl;

    } catch (error) {
      console.error(`Error processing image ${i} for issue ${issueId}:`, error);
    }
  }

  // Update issue with processed image URLs
  await admin.firestore().collection('issues').doc(issueId).update({
    images: imageUrls,
    imagesProcessed: true
  });
}

async function notifyUser(userId, type, data) {
  try {
    // Get user's FCM token
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData || !userData.fcmToken) {
      return; // User not found or no FCM token
    }

    const message = buildNotificationMessage(type, data);

    await admin.messaging().send({
      token: userData.fcmToken,
      notification: message.notification,
      data: message.data
    });

  } catch (error) {
    console.error(`Error sending notification to user ${userId}:`, error);
  }
}

async function notifyModerators(type, data) {
  try {
    // Get all moderators and admins
    const [moderators, admins] = await Promise.all([
      admin.firestore().collection('moderators').get(),
      admin.firestore().collection('admins').get()
    ]);

    const moderatorIds = [
      ...moderators.docs.map(doc => doc.id),
      ...admins.docs.map(doc => doc.id)
    ];

    // Get FCM tokens for moderators
    const tokens = [];
    for (const moderatorId of moderatorIds) {
      const userDoc = await admin.firestore().collection('users').doc(moderatorId).get();
      const userData = userDoc.data();
      if (userData && userData.fcmToken) {
        tokens.push(userData.fcmToken);
      }
    }

    if (tokens.length === 0) return;

    const message = buildNotificationMessage(type, data);

    await admin.messaging().sendMulticast({
      tokens,
      notification: message.notification,
      data: message.data
    });

  } catch (error) {
    console.error('Error notifying moderators:', error);
  }
}

function buildNotificationMessage(type, data) {
  const messages = {
    issue_flagged: {
      notification: {
        title: 'Issue Flagged for Review',
        body: `Issue "${data.content}" requires moderation`
      },
      data: {
        type: 'issue_flagged',
        issueId: data.issueId,
        reason: data.reason
      }
    },
    comment_flagged: {
      notification: {
        title: 'Comment Flagged for Review',
        body: 'A comment requires moderation'
      },
      data: {
        type: 'comment_flagged',
        commentId: data.commentId,
        reason: data.reason
      }
    },
    issue_status_changed: {
      notification: {
        title: 'Issue Status Updated',
        body: `Your issue "${data.title}" status changed from ${data.oldStatus} to ${data.newStatus}`
      },
      data: {
        type: 'issue_status_changed',
        issueId: data.issueId,
        oldStatus: data.oldStatus,
        newStatus: data.newStatus
      }
    },
    new_comment: {
      notification: {
        title: 'New Comment',
        body: `${data.commenterName} commented on your issue`
      },
      data: {
        type: 'new_comment',
        issueId: data.issueId,
        commentId: data.commentId
      }
    }
  };

  return messages[type] || {
    notification: { title: 'CivicVoice', body: 'You have a new notification' },
    data: { type }
  };
}