const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');

const farmModuleRoutes = require('./routes/farmModule.routes');
const healthRoutes = require('./routes/health.routes');
const userRoutes = require('./routes/user.routes');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/v1/health', healthRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/farm-modules', farmModuleRoutes);

app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: 'Endpoint tidak ditemukan',
    data: null,
  });
});

const port = process.env.PORT || 5000;

if (require.main === module) {
  app.listen(port, () => {
    console.log(`SeiCycle API is running on port ${port}`);
  });
}

module.exports = app;
