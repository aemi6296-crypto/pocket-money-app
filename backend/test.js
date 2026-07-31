const { db } = require('./config/firebase');

async function test() {
  try {
    console.log('Connecting to Firestore...');
    const doc = await db.collection('wallets').doc('LJy14ZdXMwN6uBlLznna6ShS0PL2').get();
    console.log('exists:', doc.exists);
    console.log('data:', JSON.stringify(doc.data()));
    process.exit(0);
  } catch (err) {
    console.log('error:', err.message);
    process.exit(1);
  }
}

test();
