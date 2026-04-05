const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
const bcrypt = require('bcrypt');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// MongoDB connection
const MONGODB_URI = 'mongodb://localhost:27017';
const DB_NAME = 'TotalApp';

// Collection names
const COLLECTIONS = {
  REGISTER: 'Mas_Register',
  CUSTOMER: 'mas_customer',
  PRODUCT: 'mas_product',
  SALESMAN: 'mas_salesman'
};

let db;
let collections = {};

async function connectToMongoDB() {
    try {
        const client = await MongoClient.connect(MONGODB_URI, {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        db = client.db(DB_NAME);
        
        // Initialize collections
        collections.register = db.collection(COLLECTIONS.REGISTER);
        collections.customer = db.collection(COLLECTIONS.CUSTOMER);
        collections.product = db.collection(COLLECTIONS.PRODUCT);
        collections.salesman = db.collection(COLLECTIONS.SALESMAN);
        
        console.log('Connected to MongoDB successfully');
        console.log(`Database: ${DB_NAME}`);
        console.log(`Collections: ${Object.values(COLLECTIONS).join(', ')}`);
        
        // Create indexes
        await collections.register.createIndex({ email: 1, role: 1 }, { unique: true });
        await collections.customer.createIndex({ customer_id: 1 }, { unique: true });
        await collections.customer.createIndex({ distributor_id: 1 });
        await collections.product.createIndex({ sku: 1 }, { unique: true });
        await collections.product.createIndex({ distributorId: 1 });
        await collections.salesman.createIndex({ salesman_id: 1 }, { unique: true });
        await collections.salesman.createIndex({ distributor_id: 1 });
        
        console.log('Indexes created successfully');
    } catch (error) {
        console.error('MongoDB connection error:', error);
        process.exit(1);
    }
}

// Helper function to generate unique IDs
function generateId(prefix) {
    return `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

// Helper function to normalize email
const normalizeEmail = (email) => email ? email.trim().toLowerCase() : '';

// Email validation regex
const validateEmail = (email) => {
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
};

// Mobile number validation (10 digits only)
const validateMobileNumber = (phone) => {
    const phoneRegex = /^\d{10}$/;
    return phoneRegex.test(phone);
};

// ==================== CUSTOMER APIs ====================

// Add new customer
app.post('/api/customers', async (req, res) => {
    try {
        const customerData = req.body;
        
        // Generate customer_id if not provided
        if (!customerData.customer_id) {
            const count = await collections.customer.countDocuments();
            customerData.customer_id = `GK${String(count + 1).padStart(3, '0')}`;
        }
        
        // Set timestamps
        customerData.created_at = customerData.created_at || new Date().toISOString();
        customerData.updated_at = new Date().toISOString();
        customerData.status = customerData.status || 'active';
        
        const result = await collections.customer.insertOne(customerData);
        
        res.json({ 
            success: true, 
            message: 'Customer added successfully',
            _id: result.insertedId,
            ...customerData
        });
    } catch (error) {
        console.error('Error adding customer:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get customers by distributor ID
app.get('/api/customers/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const customers = await collections.customer
            .find({ distributor_id: distributorId })
            .sort({ created_at: -1 })
            .toArray();
        res.json(customers);
    } catch (error) {
        console.error('Error fetching customers:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get single customer
app.get('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const customer = await collections.customer.findOne({ _id: new ObjectId(id) });
        if (!customer) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        res.json(customer);
    } catch (error) {
        console.error('Error fetching customer:', error);
        res.status(500).json({ error: error.message });
    }
});

// Update customer
app.put('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updated_at = new Date().toISOString();
        
        const result = await collections.customer.updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        
        res.json({ success: true, message: 'Customer updated successfully' });
    } catch (error) {
        console.error('Error updating customer:', error);
        res.status(500).json({ error: error.message });
    }
});

// Delete customer
app.delete('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await collections.customer.deleteOne({ _id: new ObjectId(id) });
        
        if (result.deletedCount === 0) {
            return res.status(404).json({ error: 'Customer not found' });
        }
        
        res.json({ success: true, message: 'Customer deleted successfully' });
    } catch (error) {
        console.error('Error deleting customer:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== PRODUCT APIs ====================

// Add new product
app.post('/api/products', async (req, res) => {
    try {
        const productData = req.body;
        
        // Set timestamps
        productData.createdAt = productData.createdAt || new Date().toISOString();
        productData.updatedAt = new Date().toISOString();
        productData.isActive = productData.isActive !== undefined ? productData.isActive : true;
        
        // Set stock status
        if (productData.stockQuantity !== undefined) {
            productData.stock = productData.stockQuantity >= 10 ? 'Available' : 'Low Stock';
        }
        
        const result = await collections.product.insertOne(productData);
        
        res.json({ 
            success: true, 
            message: 'Product added successfully',
            _id: result.insertedId,
            ...productData
        });
    } catch (error) {
        console.error('Error adding product:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get products by distributor ID
app.get('/api/products/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const products = await collections.product
            .find({ distributorId: distributorId, isActive: true })
            .sort({ createdAt: -1 })
            .toArray();
        res.json(products);
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get single product
app.get('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const product = await collections.product.findOne({ _id: new ObjectId(id) });
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        res.json(product);
    } catch (error) {
        console.error('Error fetching product:', error);
        res.status(500).json({ error: error.message });
    }
});

// Update product
app.put('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updatedAt = new Date().toISOString();
        
        // Update stock status
        if (updateData.stockQuantity !== undefined) {
            updateData.stock = updateData.stockQuantity >= 10 ? 'Available' : 'Low Stock';
        }
        
        const result = await collections.product.updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        res.json({ success: true, message: 'Product updated successfully' });
    } catch (error) {
        console.error('Error updating product:', error);
        res.status(500).json({ error: error.message });
    }
});

// Delete product (soft delete)
app.delete('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await collections.product.updateOne(
            { _id: new ObjectId(id) },
            { $set: { isActive: false, updatedAt: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        res.json({ success: true, message: 'Product deleted successfully' });
    } catch (error) {
        console.error('Error deleting product:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== SALESMAN APIs ====================

// Add new salesman
app.post('/api/salesmen', async (req, res) => {
    try {
        const salesmanData = req.body;
        
        // Generate salesman_id if not provided
        if (!salesmanData.salesman_id) {
            const count = await collections.salesman.countDocuments();
            salesmanData.salesman_id = `SM${String(count + 1).padStart(3, '0')}`;
        }
        
        // Set timestamps
        salesmanData.created_at = salesmanData.created_at || new Date().toISOString();
        salesmanData.updated_at = new Date().toISOString();
        salesmanData.status = salesmanData.status || 'active';
        salesmanData.achieved_amount = salesmanData.achieved_amount || 0;
        salesmanData.performance_metrics = salesmanData.performance_metrics || {};
        salesmanData.bank_details = salesmanData.bank_details || {};
        salesmanData.documents = salesmanData.documents || {};
        salesmanData.notes = salesmanData.notes || '';
        
        const result = await collections.salesman.insertOne(salesmanData);
        
        res.json({ 
            success: true, 
            message: 'Salesman added successfully',
            _id: result.insertedId,
            ...salesmanData
        });
    } catch (error) {
        console.error('Error adding salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get salesmen by distributor ID
app.get('/api/salesmen/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const salesmen = await collections.salesman
            .find({ distributor_id: distributorId })
            .sort({ created_at: -1 })
            .toArray();
        res.json(salesmen);
    } catch (error) {
        console.error('Error fetching salesmen:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get single salesman
app.get('/api/salesmen/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const salesman = await collections.salesman.findOne({ _id: new ObjectId(id) });
        if (!salesman) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        res.json(salesman);
    } catch (error) {
        console.error('Error fetching salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

// Update salesman
app.put('/api/salesmen/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updated_at = new Date().toISOString();
        
        const result = await collections.salesman.updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        res.json({ success: true, message: 'Salesman updated successfully' });
    } catch (error) {
        console.error('Error updating salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

// Delete salesman (soft delete)
app.delete('/api/salesmen/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const result = await collections.salesman.updateOne(
            { _id: new ObjectId(id) },
            { $set: { status: 'inactive', updated_at: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        res.json({ success: true, message: 'Salesman deactivated successfully' });
    } catch (error) {
        console.error('Error deleting salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== AUTH APIs ====================

// Check if user exists
app.post('/api/check-user', async (req, res) => {
    try {
        const { email, role } = req.body;
        const normalizedEmail = normalizeEmail(email);
        const user = await collections.register.findOne({ email: normalizedEmail, role });
        res.json({ exists: !!user });
    } catch (error) {
        console.error('Error checking user:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Get user details
app.post('/api/get-user', async (req, res) => {
    try {
        const { email, role } = req.body;
        const normalizedEmail = normalizeEmail(email);
        const user = await collections.register.findOne({ email: normalizedEmail, role });
        if (user) {
            const { _id, password, ...userWithoutId } = user;
            res.json(userWithoutId);
        } else {
            res.status(404).json({ error: 'User not found' });
        }
    } catch (error) {
        console.error('Error getting user:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Register new user
app.post('/api/register', async (req, res) => {
    try {
        console.log('Received registration request:', req.body);
        
        const { fullName, email, phoneNumber, password, role, accountType, createdAt, isActive } = req.body;
        
        // Validate required fields
        if (!fullName || !email || !phoneNumber || !password || !role) {
            return res.status(400).json({ 
                message: 'Missing required fields',
                error: 'All fields are required'
            });
        }
        
        // Validate email format
        if (!validateEmail(email)) {
            return res.status(400).json({ 
                message: 'Invalid email format. Please enter a valid email address (e.g., name@example.com)' 
            });
        }
        
        // Validate mobile number format (10 digits only)
        if (!validateMobileNumber(phoneNumber)) {
            return res.status(400).json({ 
                message: 'Invalid mobile number. Mobile number must be exactly 10 digits' 
            });
        }
        
        // Check if user already exists
        const normalizedEmail = normalizeEmail(email);
        const existingUser = await collections.register.findOne({ email: normalizedEmail, role });
        if (existingUser) {
            return res.status(400).json({ 
                message: 'User with this email already registered for this role' 
            });
        }

        // Hash the password
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        // Prepare user document for insertion
        const userDocument = {
            fullName: fullName,
            email: normalizedEmail,
            phoneNumber: phoneNumber,
            password: hashedPassword,
            role: role,
            accountType: accountType || 'PortalUser',
            createdAt: createdAt ? new Date(createdAt) : new Date(),
            isActive: isActive !== undefined ? isActive : true
        };
        
        console.log('Attempting to insert user:', { ...userDocument, password: '[HIDDEN]' });
        
        // Insert new user
        const result = await collections.register.insertOne(userDocument);
        
        console.log('User inserted successfully with ID:', result.insertedId);
        
        res.status(201).json({ 
            message: 'Registration successful', 
            userId: result.insertedId 
        });
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ 
            message: 'Internal server error', 
            error: error.message 
        });
    }
});

// Login endpoint
app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        console.log('Login attempt for:', { email });
        
        // Validate email format
        if (!validateEmail(email)) {
            return res.status(401).json({ message: 'Invalid email format' });
        }
        
        const normalizedEmail = normalizeEmail(email);
        
        // Find user by email across ALL roles (role-agnostic)
        const users = await collections.register.find({ email: normalizedEmail }).toArray();
        let user = null;
        
        // Check each user with matching email for correct password
        for (const u of users) {
            const isValidPassword = await bcrypt.compare(password, u.password);
            if (isValidPassword) {
                user = u;
                break; // Found matching user
            }
        }
        
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials. Email or password incorrect.' });
        }

        // Remove password and _id from response
        const { _id, password: _, ...userResponse } = user;
        res.json({ 
            success: true, 
            message: 'Login successful',
            user: userResponse 
        });
    } catch (error) {
        console.error('Error during login:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        message: 'Server is running', 
        mongodb: !!db,
        collections: Object.keys(collections).reduce((acc, key) => {
            acc[key] = !!collections[key];
            return acc;
        }, {})
    });
});

// Start server
app.listen(PORT, async () => {
    await connectToMongoDB();
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`API endpoints available at http://localhost:${PORT}/api`);
    console.log(`\nAPI Endpoints:`);
    console.log(`\nAuth:`);
    console.log(`  POST /api/login - User login`);
    console.log(`  POST /api/register - User registration`);
    console.log(`\nCustomers:`);
    console.log(`  GET /api/customers/:distributorId - Get all customers`);
    console.log(`  POST /api/customers - Add new customer`);
    console.log(`  GET /api/customers/:id - Get single customer`);
    console.log(`  PUT /api/customers/:id - Update customer`);
    console.log(`  DELETE /api/customers/:id - Delete customer`);
    console.log(`\nProducts:`);
    console.log(`  GET /api/products/:distributorId - Get all products`);
    console.log(`  POST /api/products - Add new product`);
    console.log(`  GET /api/products/:id - Get single product`);
    console.log(`  PUT /api/products/:id - Update product`);
    console.log(`  DELETE /api/products/:id - Delete product`);
    console.log(`\nSalesmen:`);
    console.log(`  GET /api/salesmen/:distributorId - Get all salesmen`);
    console.log(`  POST /api/salesmen - Add new salesman`);
    console.log(`  GET /api/salesmen/:id - Get single salesman`);
    console.log(`  PUT /api/salesmen/:id - Update salesman`);
    console.log(`  DELETE /api/salesmen/:id - Delete salesman`);
});