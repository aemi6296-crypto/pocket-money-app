const express = require('express');
const router = express.Router();
const { admin, db } = require('../config/firebase');


router.post('/add-funds', async (req, res) => {
  const { parentId, amount } = req.body;

  if (!parentId || !amount) {
    return res.status(400).json({ message: 'parentId and amount are required' });
  }

  if (amount <= 0) {
    return res.status(400).json({ message: 'Amount must be greater than 0' });
  }

  try {
    const userDoc = await db.collection('users').doc(parentId).get();

    if (!userDoc.exists) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (userDoc.data().role !== 'parent') {
      return res.status(403).json({ message: 'Only parent accounts can add funds' });
    }

    await db.collection('wallets').doc(parentId).update({
      balance: admin.firestore.FieldValue.increment(amount)
    });

    await db.collection('transactions').doc().set({
      receiverId: parentId,
      senderId: null,
      amount,
      type: 'deposit',
      description: 'Added funds to wallet',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(200).json({ message: 'Funds added ✅', amount });

  } catch (error) {
    res.status(500).json({ message: 'Failed to add funds ❌', error: error.message });
  }
});

module.exports = router;
