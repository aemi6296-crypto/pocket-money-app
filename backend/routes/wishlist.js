const express = require('express');
const router = express.Router();
const { admin, db } = require('../config/firebase');


router.post('/add', async (req, res) => {
  const { kidId, itemName, price, notes } = req.body;

  if (!kidId || !itemName) {
    return res.status(400).json({ message: 'kidId and itemName are required' });
  }

  try {
    const itemRef = db.collection('wishlist').doc();

    await itemRef.set({
      itemId: itemRef.id,
      kidId,
      itemName,
      price: price || 0,
      notes: notes || '',
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    res.status(201).json({ message: 'Item added to wish list ✅', itemId: itemRef.id });

  } catch (error) {
    res.status(500).json({ message: 'Failed to add item ❌', error: error.message });
  }
});


router.get('/:kidId', async (req, res) => {
  const { kidId } = req.params;

  try {
    const snapshot = await db.collection('wishlist')
      .where('kidId', '==', kidId)
      .orderBy('createdAt', 'desc')
      .get();

    const items = snapshot.docs.map(doc => doc.data());
    res.status(200).json({ message: 'Wish list found ✅', items });

  } catch (error) {
    res.status(500).json({ message: 'Failed to get wish list ❌', error: error.message });
  }
});

router.delete('/:itemId', async (req, res) => {
  const { itemId } = req.params;

  try {
    const itemRef = db.collection('wishlist').doc(itemId);
    const itemDoc = await itemRef.get();

    if (!itemDoc.exists) {
      return res.status(404).json({ message: 'Item not found' });
    }

    await itemRef.delete();
    res.status(200).json({ message: 'Item removed ✅' });

  } catch (error) {
    res.status(500).json({ message: 'Failed to remove item ❌', error: error.message });
  }
});

module.exports = router;
