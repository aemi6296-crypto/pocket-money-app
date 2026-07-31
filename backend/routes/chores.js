const express = require('express');
const router = express.Router();
const { admin, db, sendPushNotification } = require('../config/firebase');


router.post('/create', async (req, res) => {
  const { parentId, kidId, title, amount } = req.body;

  if (!parentId || !kidId || !title || !amount) {
    return res.status(400).json({
      message: 'parentId, kidId, title and amount are required'
    });
  }

  if (amount <= 0) {
    return res.status(400).json({ message: 'Amount must be greater than 0' });
  }

  try {
    const choreRef = db.collection('chores').doc();

    await choreRef.set({
      choreId: choreRef.id,
      parentId,
      kidId,
      title,
      amount,
      status: 'pending', 
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await sendPushNotification(
      kidId,
      'New chore! 🧹',
      `${title} — earn $${amount}`
    );

    res.status(201).json({ message: 'Chore created ✅', choreId: choreRef.id });

  } catch (error) {
    res.status(500).json({ message: 'Failed to create chore ❌', error: error.message });
  }
});


router.get('/kid/:kidId', async (req, res) => {
  const { kidId } = req.params;

  try {
    const snapshot = await db.collection('chores')
      .where('kidId', '==', kidId)
      .orderBy('createdAt', 'desc')
      .get();

    const chores = snapshot.docs.map(doc => doc.data());
    res.status(200).json({ message: 'Chores found ✅', chores });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get chores ❌', error: error.message });
  }
});


router.get('/parent/:parentId', async (req, res) => {
  const { parentId } = req.params;

  try {
    const snapshot = await db.collection('chores')
      .where('parentId', '==', parentId)
      .orderBy('createdAt', 'desc')
      .get();

    const chores = snapshot.docs.map(doc => doc.data());
    res.status(200).json({ message: 'Chores found ✅', chores });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get chores ❌', error: error.message });
  }
});


router.post('/:choreId/complete', async (req, res) => {
  const { choreId } = req.params;

  try {
    const choreRef = db.collection('chores').doc(choreId);
    const choreDoc = await choreRef.get();

    if (!choreDoc.exists) {
      return res.status(404).json({ message: 'Chore not found' });
    }

    const chore = choreDoc.data();

    if (chore.status !== 'pending') {
      return res.status(400).json({ message: 'Chore is not pending' });
    }

    await choreRef.update({
      status: 'done',
      completedAt: admin.firestore.FieldValue.serverTimestamp()
    });

    await sendPushNotification(
      chore.parentId,
      'Chore completed! ✅',
      `Your kid finished "${chore.title}" — approve to send $${chore.amount}`
    );

    res.status(200).json({ message: 'Chore marked done ✅' });

  } catch (error) {
    res.status(500).json({ message: 'Failed to update chore ❌', error: error.message });
  }
});


router.post('/:choreId/approve', async (req, res) => {
  const { choreId } = req.params;

  try {
    const choreRef = db.collection('chores').doc(choreId);
    const choreDoc = await choreRef.get();

    if (!choreDoc.exists) {
      return res.status(404).json({ message: 'Chore not found' });
    }

    const chore = choreDoc.data();

    if (chore.status !== 'done') {
      return res.status(400).json({ message: 'Chore must be marked done before approving' });
    }

    const parentWalletRef = db.collection('wallets').doc(chore.parentId);
    const kidWalletRef = db.collection('wallets').doc(chore.kidId);

    await db.runTransaction(async (t) => {
      const parentWallet = await t.get(parentWalletRef);
      const kidWallet = await t.get(kidWalletRef);

      if (!parentWallet.exists) throw new Error('Parent wallet not found');
      if (!kidWallet.exists) throw new Error('Kid wallet not found');

      if (parentWallet.data().balance < chore.amount) throw new Error('Insufficient balance');

      t.update(parentWalletRef, { balance: admin.firestore.FieldValue.increment(-chore.amount) });
      t.update(kidWalletRef, { balance: admin.firestore.FieldValue.increment(chore.amount) });
      t.update(choreRef, { status: 'approved', approvedAt: admin.firestore.FieldValue.serverTimestamp() });

      const transactionRef = db.collection('transactions').doc();
      t.set(transactionRef, {
        senderId: chore.parentId,
        receiverId: chore.kidId,
        amount: chore.amount,
        type: 'chore_payment',
        description: `Chore: ${chore.title}`,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });
    });

    await sendPushNotification(
      chore.kidId,
      'Chore approved! 🎉',
      `You earned $${chore.amount} for "${chore.title}"`
    );

    res.status(200).json({ message: 'Chore approved and paid ✅' });

  } catch (error) {
    if (error.message === 'Insufficient balance') {
      return res.status(400).json({ message: 'Insufficient balance ❌' });
    }
    res.status(500).json({ message: 'Failed to approve chore ❌', error: error.message });
  }
});


// ★ NEW: Delete a chore (parent-only action from the Chore Manager screen).
// Works regardless of the chore's current status (pending / done / approved) —
// it just removes the chore document. It does NOT reverse any wallet
// transaction that may have already happened on approval, since that's a
// completed payment, not part of the chore record itself.
router.delete('/:choreId', async (req, res) => {
  const { choreId } = req.params;

  try {
    const choreRef = db.collection('chores').doc(choreId);
    const choreDoc = await choreRef.get();

    if (!choreDoc.exists) {
      return res.status(404).json({ message: 'Chore not found' });
    }

    await choreRef.delete();

    res.status(200).json({ message: 'Chore deleted ✅' });

  } catch (error) {
    res.status(500).json({ message: 'Failed to delete chore ❌', error: error.message });
  }
});

module.exports = router;