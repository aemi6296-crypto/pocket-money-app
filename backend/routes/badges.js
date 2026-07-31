const express = require('express');
const router = express.Router();
const { db } = require('../config/firebase');

router.get('/:kidId', async (req, res) => {
  const { kidId } = req.params;

  try {
    const choresSnapshot = await db.collection('chores')
      .where('kidId', '==', kidId)
      .where('status', '==', 'approved')
      .get();
    const approvedChores = choresSnapshot.size;

    const qrSnapshot = await db.collection('transactions')
      .where('senderId', '==', kidId)
      .where('type', '==', 'qr_payment')
      .get();
    const qrPayments = qrSnapshot.size;

    const piggyDoc = await db.collection('piggybanks').doc(kidId).get();
    const piggy = piggyDoc.exists ? piggyDoc.data() : { savedAmount: 0, targetAmount: 0 };
    const goalReached = piggy.targetAmount > 0 && piggy.savedAmount >= piggy.targetAmount;

    const wishSnapshot = await db.collection('wishlist')
      .where('kidId', '==', kidId)
      .get();
    const wishlistItems = wishSnapshot.size;

    const transferSnapshot = await db.collection('transactions')
      .where('receiverId', '==', kidId)
      .where('type', '==', 'transfer')
      .get();
    const transfersReceived = transferSnapshot.size;

    
    const badges = [
      {
        id: 'first_chore',
        title: 'First Chore Done',
        description: 'Complete your first chore',
        earned: approvedChores >= 1,
        progress: Math.min(approvedChores, 1),
        total: 1
      },
      {
        id: 'chore_star',
        title: 'Chore Star',
        description: 'Complete 5 chores',
        earned: approvedChores >= 5,
        progress: Math.min(approvedChores, 5),
        total: 5
      },
      {
        id: 'smart_spender',
        title: 'Smart Spender',
        description: 'Make your first QR payment',
        earned: qrPayments >= 1,
        progress: Math.min(qrPayments, 1),
        total: 1
      },
      {
        id: 'goal_getter',
        title: 'Goal Getter',
        description: 'Reach your piggy bank target',
        earned: goalReached,
        progress: goalReached ? 1 : 0,
        total: 1
      },
      {
        id: 'dreamer',
        title: 'Dreamer',
        description: 'Add something to your wish list',
        earned: wishlistItems >= 1,
        progress: Math.min(wishlistItems, 1),
        total: 1
      },
      {
        id: 'money_receiver',
        title: 'First Allowance',
        description: 'Receive money from your parent',
        earned: transfersReceived >= 1,
        progress: Math.min(transfersReceived, 1),
        total: 1
      }
    ];

    
    const earnedCount = badges.filter(b => b.earned).length;
    const totalBadges = badges.length;

    let level;
    if (earnedCount === 0) {
      level = { number: 1, title: 'Beginner', next: 'Complete a chore or add a wish list item' };
    } else if (earnedCount <= 2) {
      level = { number: 2, title: 'Learner', next: 'Earn more badges to reach Level 3' };
    } else if (earnedCount === 3) {
      level = { number: 3, title: 'Saver', next: 'Just 2 more badges for Level 4' };
    } else if (earnedCount === 4) {
      level = { number: 4, title: 'Smart Kid', next: 'One more badge for Money Master!' };
    } else {
      level = { number: 5, title: 'Money Master', next: 'You have unlocked everything!' };
    }

    res.status(200).json({
      message: 'Badges loaded ✅',
      level,
      earnedCount,
      totalBadges,
      badges
    });

  } catch (error) {
    res.status(500).json({ message: 'Failed to load badges ❌', error: error.message });
  }
});

module.exports = router;
