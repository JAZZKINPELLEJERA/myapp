
const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');

// Initialize Firebase Admin SDK
const serviceAccount = require('../serviceAccountKey.json'); // Make sure this path is correct

initializeApp({
  credential: cert(serviceAccount)
});

const db = getFirestore();

async function addSampleTransactions() {
  const transactionsCollection = db.collection('transactions');

  const transactions = [
    {
      dateTime: new Date('2025-12-11T23:07:00'),
      amount: 10.00,
      paymentMethod: 'Cash',
      items: [
        { name: 'Coffee', quantity: 1, price: 10.00 },
      ]
    },
    {
      dateTime: new Date('2025-12-11T22:15:00'),
      amount: 30.00,
      paymentMethod: 'Utang',
      customerName: 'jake',
      items: [
        { name: 'Burger', quantity: 1, price: 20.00 },
        { name: 'Fries', quantity: 1, price: 10.00 },
      ]
    },
    {
      dateTime: new Date('2025-12-11T19:45:00'),
      amount: 15.50,
      paymentMethod: 'Cash',
      items: [
        { name: 'Ice Cream', quantity: 1, price: 15.50 },
      ]
    },
    {
      dateTime: new Date('2025-12-10T14:20:00'),
      amount: 250.00,
      paymentMethod: 'Utang',
      customerName: 'amy',
      items: [
        { name: 'Pizza', quantity: 2, price: 125.00 },
      ]
    },
    {
      dateTime: new Date('2025-12-10T11:30:00'),
      amount: 5.25,
      paymentMethod: 'Cash',
      items: [
        { name: 'Soda', quantity: 1, price: 5.25 },
      ]
    },
  ];

  for (const transaction of transactions) {
    await transactionsCollection.add(transaction);
  }

  console.log('Sample transactions added successfully!');
}

addSampleTransactions();
