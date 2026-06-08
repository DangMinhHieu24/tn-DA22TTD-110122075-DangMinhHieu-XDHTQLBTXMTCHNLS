const { PrismaClient } = require('@prisma/client');

async function test() {
  const prisma = new PrismaClient();
  const appointments = await prisma.appointment.findMany();
  if (appointments.length === 0) {
    console.log('No appointments to test delete.');
    return;
  }
  const id = appointments[0].id;
  console.log('Testing delete for id:', id);

  // We need an admin token. Let's find an admin user.
  const admin = await prisma.user.findFirst({ where: { role: 'ADMIN' } });
  if (!admin) {
    console.log('No admin found.');
    return;
  }

  // Generate a token for the admin using the same logic as auth controller
  const jwt = require('jsonwebtoken');
  const token = jwt.sign(
    { userId: admin.id, role: admin.role },
    process.env.JWT_SECRET || 'supersecret_jwt_key_for_dev',
    { expiresIn: '7d' }
  );

  try {
    const res = await fetch(`http://localhost:3000/api/appointments/${id}`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` }
    });
    const data = await res.json();
    console.log('Delete result:', res.status, data);
  } catch (err) {
    console.log('Delete error:', err.message);
  }
}

test();
