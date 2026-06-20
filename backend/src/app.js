const cors = require('cors');
const dotenv = require('dotenv');
const express = require('express');

const {
  errorHandler,
  notFoundHandler,
} = require('./middlewares/errorHandler');
const calendarRoutes = require('./routes/calendar.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const educationRoutes = require('./routes/education.routes');
const farmModuleRoutes = require('./routes/farmModule.routes');
const financeRoutes = require('./routes/finance.routes');
const healthRoutes = require('./routes/health.routes');
const inventoryRoutes = require('./routes/inventory.routes');
const logbookRoutes = require('./routes/logbook.routes');
const reportRoutes = require('./routes/report.routes');
const userRoutes = require('./routes/user.routes');

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

app.use('/api/v1/health', healthRoutes);
app.use('/api/v1/users', userRoutes);
app.use('/api/v1/farm-modules', farmModuleRoutes);
app.use('/api/v1/dashboard', dashboardRoutes);
app.use('/api/v1/logbooks', logbookRoutes);
app.use('/api/v1/inventory', inventoryRoutes);
app.use('/api/v1/calendar', calendarRoutes);
app.use('/api/v1/finance', financeRoutes);
app.use('/api/v1/education', educationRoutes);
app.use('/api/v1/reports', reportRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

const port = process.env.PORT || 5000;

if (require.main === module) {
  app.listen(port, () => {
    console.log(`SeiCycle API is running on port ${port}`);
  });
}

module.exports = app;
