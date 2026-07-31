const express = require('express');
const router = express.Router();
const { admin, db, sendPushNotification } = require('../config/firebase');

router.post('/set-target', async (req, res) => {
  const { kidId, targetAmount } = req.body;

  if (!kidId || !targetAmount) {
    return res.status(400).json({ message: 'kidId and targetAmount are required' });
  }

  if (targetAmount <= 0) {
    return res.status(400).json({ message: 'Target must be greater than 0' });
  }

  try {
    const piggyRef = db.collection('piggybanks').doc(kidId);
    const piggyDoc = await piggyRef.get();

    if (piggyDoc.exists) {
      await piggyRef.update({ targetAmount });
    } else {
      await piggyRef.set({
        kidId,
        targetAmount,
        savedAmount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    }

    res.status(200).json({ message: 'Savings target set ✅', targetAmount });

  } catch (error) {
    res.status(500).json({ message: 'Failed to set target ❌', error: error.message });
  }
});


router.post('/deposit', async (req, res) => {
  const { kidId, amount } = req.body;

  if (!kidId || !amount) {
    return res.status(400).json({ message: 'kidId and amount are required' });
  }

  if (amount <= 0) {
    return res.status(400).json({ message: 'Amount must be greater than 0' });
  }

  try {
    const walletRef = db.collection('wallets').doc(kidId);
    const piggyRef = db.collection('piggybanks').doc(kidId);

    let goalJustReached = false;

    await db.runTransaction(async (t) => {
      const walletDoc = await t.get(walletRef);
      const piggyDoc = await t.get(piggyRef);

      if (!walletDoc.exists) throw new Error('Wallet not found');
      if (!piggyDoc.exists) throw new Error('No savings target set yet');

      const walletBalance = walletDoc.data().balance;
      if (walletBalance < amount) throw new Error('Insufficient balance');

      const piggy = piggyDoc.data();
      const wasBelow = piggy.savedAmount < piggy.targetAmount;
      const newSaved = piggy.savedAmount + amount;

      if (wasBelow && newSaved >= piggy.targetAmount) {
        goalJustReached = true;
      }

      t.update(walletRef, { balance: admin.firestore.FieldValue.increment(-amount) });
      t.update(piggyRef, { savedAmount: admin.firestore.FieldValue.increment(amount) });
    });

    if (goalJustReached) {
      await sendPushNotification(kidId, 'Goal reached! 🎉', 'You hit your savings target!');
    }

    res.status(200).json({ message: 'Deposit successful ✅', amount });

  } catch (error) {
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ message: 'Insufficient balance ❌' });
    }
    if (error.message === 'No savings target set yet') {
      return res.status(400).json({ message: 'Set a savings target first ❌' });
    }
    res.status(500).json({ message: 'Deposit failed ❌', error: error.message });
  }
});


router.post('/withdraw', async (req, res) => {
  const { kidId, amount } = req.body;

  if (!kidId || !amount) {
    return res.status(400).json({ message: 'kidId and amount are required' });
  }

  try {
    const walletRef = db.collection('wallets').doc(kidId);
    const piggyRef = db.collection('piggybanks').doc(kidId);

    await db.runTransaction(async (t) => {
      const piggyDoc = await t.get(piggyRef);

      if (!piggyDoc.exists) throw new Error('No piggy bank found');
      if (piggyDoc.data().savedAmount < amount) throw new Error('Not enough saved');

      t.update(piggyRef, { savedAmount: admin.firestore.FieldValue.increment(-amount) });
      t.update(walletRef, { balance: admin.firestore.FieldValue.increment(amount) });
    });

    res.status(200).json({ message: 'Withdraw successful ✅', amount });

  } catch (error) {
    if (error.message === 'Not enough saved') {
      return res.status(400).json({ message: 'Not enough saved to withdraw that much ❌' });
    }
    res.status(500).json({ message: 'Withdraw failed ❌', error: error.message });
  }
});


router.get('/:kidId', async (req, res) => {
  const { kidId } = req.params;

  try {
    const piggyDoc = await db.collection('piggybanks').doc(kidId).get();

    if (!piggyDoc.exists) {
      return res.status(200).json({ message: 'No piggy bank yet', targetAmount: 0, savedAmount: 0 });
    }

    res.status(200).json({ message: 'Piggy bank found ✅', ...piggyDoc.data() });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get piggy bank ❌', error: error.message });
  }
});

module.exports = router;
