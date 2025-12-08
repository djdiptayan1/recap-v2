import express from 'express';
import morgan from 'morgan';
import { dbCheckMiddleware } from './middleware/dbCheck.js';
import routes from './routes/index.js';

const app = express();

app.use(morgan('dev'));

app.use(express.json({ limit: '50mb' }));
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

app.use(dbCheckMiddleware);

// API routes
app.use('/api', routes);

app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'ok',
        message: 'Server is running and Firebase is connected',
        timestamp: new Date().toISOString()
    });
});

app.get('/', (req, res) => {
    res.status(200).json({
        message: 'Welcome to Recap Backend API',
        version: '1.0.0'
    });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({
        error: 'Not Found',
        message: 'The requested resource does not exist'
    });
});

// Error handler
app.use((err, req, res, next) => {
    console.error('Error:', err);
    res.status(err.status || 500).json({
        error: err.message || 'Internal Server Error',
        ...(process.env.NODE_ENV === 'development' && { stack: err.stack })
    });
});

export default app;
