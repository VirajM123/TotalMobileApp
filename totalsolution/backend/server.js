const express = require('express');
const { MongoClient, ObjectId } = require('mongodb');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const XLSX = require('xlsx');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = './uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'payment-' + uniqueSuffix + path.extname(file.originalname));
  }
});
const upload = multer({ storage: storage });

// Configure multer for Excel file uploads
const excelStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = './excel_uploads';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'import-' + uniqueSuffix + path.extname(file.originalname));
  }
});
const excelUpload = multer({ storage: excelStorage });

// Serve static files for logo
app.use('/isset', express.static(path.join(__dirname, 'isset')));

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use('/uploads', express.static('uploads'));

// MongoDB connection
const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017';
const DB_NAME = 'TotalApp';

// Collection names
const COLLECTIONS = {
  REGISTER: 'Mas_Register',
  CUSTOMER: 'mas_customer',
  PRODUCT: 'mas_product',
  SALESMAN: 'mas_salesman',
  DISTRIBUTOR: 'mas_distributor',
  ORDER: 'mas_order',
  PAYMENT: 'mas_payment',
  NOTIFICATION: 'mas_notification',
  COLLECTION_HISTORY: 'mas_collection_history'
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
        
        collections.register = db.collection(COLLECTIONS.REGISTER);
        collections.customer = db.collection(COLLECTIONS.CUSTOMER);
        collections.product = db.collection(COLLECTIONS.PRODUCT);
        collections.salesman = db.collection(COLLECTIONS.SALESMAN);
        collections.distributor = db.collection(COLLECTIONS.DISTRIBUTOR);
        collections.order = db.collection(COLLECTIONS.ORDER);
        collections.payment = db.collection(COLLECTIONS.PAYMENT);
        collections.notification = db.collection(COLLECTIONS.NOTIFICATION);
        collections.collectionHistory = db.collection(COLLECTIONS.COLLECTION_HISTORY);
        
        console.log('Connected to MongoDB successfully');
        console.log(`Database: ${DB_NAME}`);
        
        await collections.register.createIndex({ email: 1, role: 1 }, { unique: true });
        await collections.customer.createIndex(
  { customer_id: 1, distributor_id: 1 },
{ unique: true }
);
        await collections.customer.createIndex({ distributor_id: 1 });
        await collections.product.createIndex({ sku: 1 }, { unique: true });
        await collections.product.createIndex({ distributorId: 1 });
        await collections.salesman.createIndex({ salesman_id: 1 }, { unique: true });
        await collections.salesman.createIndex({ distributor_id: 1 });
        await collections.salesman.createIndex({ email: 1 });
        await collections.distributor.createIndex({ distributor_id: 1 }, { unique: true });
        await collections.distributor.createIndex({ email: 1 });
        await collections.order.createIndex({ orderNumber: 1 }, { unique: true });
        await collections.order.createIndex({ salesman_id: 1 });
        await collections.order.createIndex({ distributor_id: 1 });
        await collections.order.createIndex({ customerId: 1 });
        await collections.order.createIndex({ customerName: 1 });
        await collections.order.createIndex({ order_date: 1 });
        await collections.order.createIndex({ status: 1 }); // Added index for status field
        await collections.payment.createIndex({ collection_id: 1 }, { unique: true });
        await collections.payment.createIndex({ customer_id: 1 });
        await collections.payment.createIndex({ 'collected_by.id': 1 });
        await collections.payment.createIndex({ 'salesman_details.id': 1 });
        await collections.notification.createIndex({ distributor_id: 1 });
        await collections.notification.createIndex({ isRead: 1 });
        await collections.notification.createIndex({ createdAt: -1 });
        await collections.collectionHistory.createIndex({ distributor_id: 1 });
        await collections.collectionHistory.createIndex({ salesman_id: 1 });
        await collections.collectionHistory.createIndex({ created_at: -1 });
        
        console.log('Indexes created successfully');
    } catch (error) {
        console.error('MongoDB connection error:', error);
        process.exit(1);
    }
}

function generateDistributorId() {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    return `DIST${timestamp}${random}`;
}

function generateCollectionId() {
    const date = new Date();
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const random = Math.floor(Math.random() * 1000).toString().padStart(3, '0');
    return `COL-${year}${month}${day}-${random}`;
}

function generateId(prefix) {
    return `${prefix}${Date.now()}${Math.floor(Math.random() * 1000)}`;
}

const normalizeEmail = (email) => email ? email.trim().toLowerCase() : '';

const validateEmail = (email) => {
    const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
    return emailRegex.test(email);
};

const validateMobileNumber = (phone) => {
    const phoneRegex = /^\d{10}$/;
    return phoneRegex.test(phone);
};

const validateAlphabetOnly = (text) => {
    const alphabetRegex = /^[a-zA-Z\s]+$/;
    return alphabetRegex.test(text);
};

const INDIAN_BANKS = [
    'State Bank of India', 'HDFC Bank', 'ICICI Bank', 'Axis Bank', 'Kotak Mahindra Bank',
    'Bank of Baroda', 'Punjab National Bank', 'Canara Bank', 'Union Bank of India',
    'Bank of India', 'Yes Bank', 'IDFC First Bank', 'IndusInd Bank', 'Central Bank of India',
    'Indian Bank', 'UCO Bank', 'Bank of Maharashtra', 'Punjab & Sind Bank', 'Indian Overseas Bank',
    'RBL Bank', 'South Indian Bank', 'Federal Bank', 'Karur Vysya Bank', 'City Union Bank',
    'DBS Bank', 'Standard Chartered Bank', 'Citibank', 'HSBC'
];

const UPI_APPS = ['GPay', 'PhonePe', 'Paytm', 'Amazon Pay', 'WhatsApp Pay', 'Other'];

// Helper function to get customer by ID (either ObjectId or customer_id string)
async function getCustomerById(customerIdentifier) {
    let customer = null;
    
    // Try to find by ObjectId
    if (ObjectId.isValid(customerIdentifier) && customerIdentifier.length === 24) {
        customer = await collections.customer.findOne({ _id: new ObjectId(customerIdentifier) });
    }
    
    // If not found, try by customer_id string
    if (!customer && customerIdentifier) {
        customer = await collections.customer.findOne({ customer_id: customerIdentifier });
    }
    
    return customer;
}

// Helper function to get salesman by ID (either ObjectId or salesman_id string)
async function getSalesmanById(salesmanIdentifier) {
    let salesman = null;
    
    // Try to find by ObjectId
    if (ObjectId.isValid(salesmanIdentifier) && salesmanIdentifier.length === 24) {
        salesman = await collections.salesman.findOne({ _id: new ObjectId(salesmanIdentifier) });
    }
    
    // If not found, try by salesman_id string
    if (!salesman && salesmanIdentifier) {
        salesman = await collections.salesman.findOne({ salesman_id: salesmanIdentifier });
    }
    
    // If still not found, try by email in register
    if (!salesman && salesmanIdentifier && salesmanIdentifier.includes('@')) {
        const registerUser = await collections.register.findOne({ email: salesmanIdentifier, role: 'salesman' });
        if (registerUser && registerUser.salesman_id) {
            salesman = await collections.salesman.findOne({ salesman_id: registerUser.salesman_id });
        }
    }
    
    return salesman;
}

// Helper function to get distributor by ID
async function getDistributorById(distributorIdentifier) {
    let distributor = null;
    
    // Try to find by ObjectId
    if (ObjectId.isValid(distributorIdentifier) && distributorIdentifier.length === 24) {
        distributor = await collections.distributor.findOne({ _id: new ObjectId(distributorIdentifier) });
    }
    
    // If not found, try by distributor_id string
    if (!distributor && distributorIdentifier) {
        distributor = await collections.distributor.findOne({ distributor_id: distributorIdentifier });
    }
    
    return distributor;
}

// Helper function to get register user by ID
async function getRegisterUserById(userId) {
    let user = null;
    
    // Try to find by ObjectId
    if (ObjectId.isValid(userId) && userId.length === 24) {
        user = await collections.register.findOne({ _id: new ObjectId(userId) });
    }
    
    // If not found, try by salesman_id
    if (!user && userId) {
        user = await collections.register.findOne({ salesman_id: userId });
    }
    
    // If not found, try by distributor_id
    if (!user && userId) {
        user = await collections.register.findOne({ distributor_id: userId });
    }
    
    return user;
}

// Helper function to get product MRP by product ID or SKU
async function getProductMrp(productId, sku) {
    try {
        let product = null;
        
        // Try to find by ObjectId
        if (productId && ObjectId.isValid(productId)) {
            product = await collections.product.findOne({ _id: new ObjectId(productId) });
        }
        
        // If not found, try by sku
        if (!product && sku) {
            product = await collections.product.findOne({ sku: sku });
        }
        
        // If not found, try by productId as string
        if (!product && productId && !ObjectId.isValid(productId)) {
            product = await collections.product.findOne({ _id: productId });
        }
        
        // Return MRP if found, otherwise return 0
        if (product) {
            return product.mrp || product.price || 0;
        }
        return 0;
    } catch (error) {
        console.error('Error fetching product MRP:', error);
        return 0;
    }
}

// Helper function to process order items and ensure MRP is included
async function processOrderItems(items) {
    const processedItems = [];
    
    for (const item of items) {
        // Get MRP from database if not provided
        let mrpValue = item.mrp || 0;
        
        if (!mrpValue || mrpValue === 0) {
            mrpValue = await getProductMrp(item.productId, item.sku);
            console.log(`Fetched MRP for product ${item.productName || item.sku}: ${mrpValue}`);
        }
        
        // Calculate amount if not provided
        const quantity = parseInt(item.quantity) || 0;
        const rate = parseFloat(item.rate) || parseFloat(item.price) || 0;
// No rounding - keep as is
        const amount = (quantity * rate) || item.amount || 0;
        
        processedItems.push({
            productId: item.productId,
            productName: item.productName,
            sku: item.sku,
            quantity: quantity,
            rate: rate,
            amount: amount,
            mrp: mrpValue,
            price: rate, // For backward compatibility
            product_id: item.productId // For backward compatibility
        });
    }
    
    return processedItems;
}

// ==================== COLLECTION HISTORY APIs ====================

// Create collection history entry - FIXED: Now uses proper IDs
async function createCollectionHistory(order, paymentAmount, paymentMode, collectedBy, collectedByName, collectedByType, salesmanId, salesmanName) {
    try {
        // Get the actual customer to get the correct customer_id
        let actualCustomerId = order.customerId;
        let actualCustomerName = order.customerName;
        
        const customer = await getCustomerById(order.customerId);
        if (customer) {
            actualCustomerId = customer.customer_id || order.customerId;
            actualCustomerName = customer.name || order.customerName;
        }
        
        // Get the actual salesman details
        let actualSalesmanId = salesmanId;
        let actualSalesmanName = salesmanName;
        
        if (salesmanId) {
            const salesman = await getSalesmanById(salesmanId);
            if (salesman) {
                actualSalesmanId = salesman.salesman_id || salesmanId;
                actualSalesmanName = salesman.name || salesmanName;
            } else {
                // Try to find in register
                const registerUser = await getRegisterUserById(salesmanId);
                if (registerUser && registerUser.salesman_id) {
                    actualSalesmanId = registerUser.salesman_id;
                    actualSalesmanName = registerUser.fullName || salesmanName;
                }
            }
        }
        
        // Get distributor ID from order
        const distributorId = order.distributor_id;
        
        const collectionHistory = {
            collection_id: generateCollectionId(),
            order_id: order.orderNumber,
            order_amount: order.grand_total,
            amount_collected: paymentAmount,
            payment_mode: paymentMode,
            customer_id: actualCustomerId,
            customer_name: actualCustomerName,
            distributor_id: distributorId,
            collected_by: {
                type: collectedByType,
                id: collectedBy,
                name: collectedByName
            },
            salesman_details: actualSalesmanId ? {
                id: actualSalesmanId,
                name: actualSalesmanName
            } : null,
            bill_no: order.orderNumber,
            collection_date: new Date().toISOString(),
            created_at: new Date().toISOString(),
            status: 'completed'
        };
        
        await collections.collectionHistory.insertOne(collectionHistory);
        console.log(`Collection history created for order ${order.orderNumber} with customer_id: ${actualCustomerId}, salesman_id: ${actualSalesmanId}, distributor_id: ${distributorId}`);
        
        return collectionHistory;
    } catch (error) {
        console.error('Error creating collection history:', error);
    }
}

// Get collection history for distributor
app.get('/api/collection-history/distributor/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const { startDate, endDate, salesmanId } = req.query;
        
        let query = { distributor_id: distributorId };
        
        if (salesmanId && salesmanId !== 'all') {
            query['salesman_details.id'] = salesmanId;
        }
        
        if (startDate || endDate) {
            query.collection_date = {};
            if (startDate) {
                query.collection_date.$gte = new Date(startDate).toISOString();
            }
            if (endDate) {
                query.collection_date.$lte = new Date(endDate).toISOString();
            }
        }
        
        const collections = await collections.collectionHistory
            .find(query)
            .sort({ collection_date: -1 })
            .toArray();
        
        // Calculate totals
        const totalCollected = collections.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
        
        // Group by salesman
        const salesmanSummary = {};
        collections.forEach(c => {
            if (c.salesman_details && c.salesman_details.id) {
                const salesmanIdKey = c.salesman_details.id;
                if (!salesmanSummary[salesmanIdKey]) {
                    salesmanSummary[salesmanIdKey] = {
                        salesman_id: c.salesman_details.id,
                        salesman_name: c.salesman_details.name,
                        total_collected: 0,
                        count: 0
                    };
                }
                salesmanSummary[salesmanIdKey].total_collected += c.amount_collected;
                salesmanSummary[salesmanIdKey].count++;
            }
        });
        
        res.json({
            collections: collections,
            summary: {
                total_collected: totalCollected,
                total_transactions: collections.length,
                salesman_wise: Object.values(salesmanSummary)
            }
        });
    } catch (error) {
        console.error('Error fetching collection history:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get collection history for salesman
app.get('/api/collection-history/salesman/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        const { startDate, endDate } = req.query;
        
        let query = { 'salesman_details.id': salesmanId };
        
        if (startDate || endDate) {
            query.collection_date = {};
            if (startDate) {
                query.collection_date.$gte = new Date(startDate).toISOString();
            }
            if (endDate) {
                query.collection_date.$lte = new Date(endDate).toISOString();
            }
        }
        
        const collections = await collections.collectionHistory
            .find(query)
            .sort({ collection_date: -1 })
            .toArray();
        
        const totalCollected = collections.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
        
        res.json({
            collections: collections,
            summary: {
                total_collected: totalCollected,
                total_transactions: collections.length
            }
        });
    } catch (error) {
        console.error('Error fetching salesman collection history:', error);
        res.status(500).json({ error: error.message });
    }
});

// Get collection reconciliation report
app.get('/api/collection-history/reconcile/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const { expectedAmount, date } = req.query;
        
        let query = { distributor_id: distributorId };
        
        if (date) {
            const startDate = new Date(date);
            startDate.setHours(0, 0, 0, 0);
            const endDate = new Date(date);
            endDate.setHours(23, 59, 59, 999);
            query.collection_date = {
                $gte: startDate.toISOString(),
                $lte: endDate.toISOString()
            };
        }
        
        const collections = await collections.collectionHistory
            .find(query)
            .sort({ collection_date: -1 })
            .toArray();
        
        const totalCollected = collections.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
        const expected = parseFloat(expectedAmount) || totalCollected;
        const difference = expected - totalCollected;
        
        // Group by salesman for discrepancy tracking
        const salesmanCollections = {};
        collections.forEach(c => {
            if (c.salesman_details && c.salesman_details.id) {
                const id = c.salesman_details.id;
                if (!salesmanCollections[id]) {
                    salesmanCollections[id] = {
                        salesman_id: id,
                        salesman_name: c.salesman_details.name,
                        total_collected: 0,
                        collections: []
                    };
                }
                salesmanCollections[id].total_collected += c.amount_collected;
                salesmanCollections[id].collections.push(c);
            }
        });
        
        res.json({
            total_collected: totalCollected,
            expected_amount: expected,
            difference: difference,
            is_matching: difference === 0,
            message: difference === 0 ? 'Collections match expected amount' : (difference > 0 ? `Cash short by ₹${difference}` : `Cash excess by ₹${Math.abs(difference)}`),
            collections: collections,
            salesman_breakdown: Object.values(salesmanCollections)
        });
    } catch (error) {
        console.error('Error reconciling collections:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== IMPORT MASTER DATA APIs ====================

// Import customers from Excel
app.post('/api/import/customers', excelUpload.single('file'), async (req, res) => {
    try {
        const { distributorId, createdBy, updateExisting } = req.body;
        
        console.log('Import customers request received');
        console.log('Distributor ID:', distributorId);
        console.log('Update existing:', updateExisting);
        console.log('File received:', req.file ? req.file.originalname : 'No file');
        
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded', success: false });
        }
        
        if (!distributorId || distributorId === 'undefined' || distributorId === 'null') {
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            return res.status(400).json({ error: 'Valid Distributor ID is required', success: false });
        }
        
        const workbook = XLSX.readFile(req.file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        console.log(`Found ${data.length} rows in Excel file`);
        
        if (!data || data.length === 0) {
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            return res.status(400).json({ error: 'No data found in Excel file', success: false });
        }
        
        let importedCount = 0;
        let updatedCount = 0;
        let skippedCount = 0;
        const errors = [];
        
        for (let i = 0; i < data.length; i++) {
            const row = data[i];
            try {
                const customerCode = row['Customer Code'] || row['customer_code'] || row['CustomerCode'] || row['Customer code'] || '';
                const customerName = row['Customer Name'] || row['customer_name'] || row['CustomerName'] || row['Customer name'] || '';
                const area = row['Area'] || row['area'] || '';
                const route = row['Route'] || row['route'] || '';
                const address = row['Address'] || row['address'] || '';
                const phone = row['Phone'] || row['phone'] || row['Mobile'] || row['mobile'] || '';
                const distributorIdFromExcel = row['Distributor id'] || row['distributor_id'] || row['DistributorId'] || row['Distributor Id'] || distributorId;
                
                console.log(`Processing row ${i + 1}: Name=${customerName}, Area=${area}, Code=${customerCode}`);
                
                if (!customerName || !customerName.toString().trim()) {
                    console.log(`Skipping row ${i + 1}: Missing customer name`);
                    skippedCount++;
                    errors.push(`Row ${i + 1}: Missing customer name`);
                    continue;
                }
                
                if (!area || !area.toString().trim()) {
                    console.log(`Skipping row ${i + 1}: Missing area`);
                    skippedCount++;
                    errors.push(`Row ${i + 1}: Missing area for customer "${customerName}"`);
                    continue;
                }
                
                const trimmedCustomerName = customerName.toString().trim();
                const trimmedArea = area.toString().trim();
                const trimmedRoute = route ? route.toString().trim() : null;
                const trimmedAddress = address ? address.toString().trim() : null;
                const trimmedPhone = phone ? phone.toString().trim() : '';
                const trimmedDistributorId = distributorIdFromExcel ? distributorIdFromExcel.toString().trim() : distributorId;
                
              const existingCustomer = await collections.customer.findOne({
    customer_id: customerCode ? customerCode.toString().trim() : null,
    distributor_id: trimmedDistributorId
});

if (existingCustomer) {

    if (updateExisting === 'true') {

        const updateResult = await collections.customer.updateOne(
           {
    customer_id: customerCode ? customerCode.toString().trim() : null,
    distributor_id: trimmedDistributorId
  },
  {
    $set: {
      name: trimmedCustomerName,
      phone: trimmedPhone,
      area: trimmedArea,
      route: trimmedRoute,
      address: trimmedAddress,
      updated_at: new Date().toISOString(),
      updated_by: createdBy || 'import'
    }
  },
  { upsert: true }
);

        updatedCount++;
        console.log(`Updated customer ${updatedCount}: ${trimmedCustomerName}`);

    } else {

        console.log(`Skipping row ${i + 1}: Customer "${trimmedCustomerName}" already exists for this distributor`);
        skippedCount++;

        errors.push(`Row ${i + 1}: Customer "${trimmedCustomerName}" already exists for this distributor`);

    }

    continue;
}
                
                const customerId = (customerCode && customerCode.toString().trim()) 
                    ? customerCode.toString().trim() 
                    : `GK${Date.now()}${Math.floor(Math.random() * 1000)}`;
                
                const customer = {
                    name: trimmedCustomerName,
                    customer_id: customerId,
                    phone: trimmedPhone || null,
                    area: trimmedArea,
                    route: trimmedRoute,
                    address: trimmedAddress,
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString(),
                    status: 'active',
                    created_by: createdBy || 'import',
                    distributor_id: trimmedDistributorId
                };
                
                await collections.customer.insertOne(customer);
                importedCount++;
                console.log(`Imported customer ${importedCount}: ${trimmedCustomerName} with ID: ${customerId}`);
                
            } catch (rowError) {
                console.error(`Error importing row ${i + 1}:`, rowError);
                skippedCount++;
                errors.push(`Row ${i + 1}: ${rowError.message}`);
            }
        }
        
        if (fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
        
        console.log(`Import completed: ${importedCount} imported, ${updatedCount} updated, ${skippedCount} skipped`);
        
        res.json({
            success: true,
            message: `Imported ${importedCount} customers, updated ${updatedCount} customers successfully. Skipped ${skippedCount} entries.`,
            importedCount: importedCount,
            updatedCount: updatedCount,
            skippedCount: skippedCount,
            errors: errors.length > 0 ? errors.slice(0, 10) : []
        });
        
    } catch (error) {
        console.error('Error importing customers:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            try {
                fs.unlinkSync(req.file.path);
            } catch (unlinkError) {
                console.error('Error cleaning up file:', unlinkError);
            }
        }
        res.status(500).json({ error: error.message, success: false });
    }
});

// Import products from Excel
app.post('/api/import/products', excelUpload.single('file'), async (req, res) => {
    try {
        const { distributorId, createdBy, updateExisting } = req.body;
        
        console.log('Import products request received');
        console.log('Distributor ID:', distributorId);
        console.log('Update existing:', updateExisting);
        console.log('File received:', req.file ? req.file.originalname : 'No file');
        
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded', success: false });
        }
        
        if (!distributorId || distributorId === 'undefined' || distributorId === 'null') {
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            return res.status(400).json({ error: 'Valid Distributor ID is required', success: false });
        }
        
        const workbook = XLSX.readFile(req.file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        console.log(`Found ${data.length} rows in Excel file`);
        
        if (!data || data.length === 0) {
            if (fs.existsSync(req.file.path)) {
                fs.unlinkSync(req.file.path);
            }
            return res.status(400).json({ error: 'No data found in Excel file', success: false });
        }
        
        let importedCount = 0;
        let updatedCount = 0;
        let skippedCount = 0;
        const errors = [];
        
        for (let i = 0; i < data.length; i++) {
            const row = data[i];
            try {
                const productName = row['product name'] || row['product_name'] || row['Product Name'] || row['ProductName'] || row['Product name'] || '';
                const productCode = row['Product code'] || row['product_code'] || row['ProductCode'] || row['Product Code'] || row['SKU'] || row['sku'] || '';
                const mrp = parseFloat(row['MRP'] || row['mrp'] || 0);
                const price = parseFloat(row['Price'] || row['price'] || 0);
                const category = row['Category'] || row['category'] || '';
                const stockQuantity = parseInt(row['Stock Quantity'] || row['stock_quantity'] || row['Stock'] || row['stock'] || 0);
                const description = row['Description'] || row['description'] || '';
                const distributorIdFromExcel = row['Distirbutor Id'] || row['distributor_id'] || row['DistributorId'] || row['Distributor Id'] || distributorId;
                
                console.log(`Processing row ${i + 1}: Name=${productName}, Code=${productCode}, Price=${price}`);
                
                if (!productName || !productName.toString().trim()) {
                    console.log(`Skipping row ${i + 1}: Missing product name`);
                    skippedCount++;
                    errors.push(`Row ${i + 1}: Missing product name`);
                    continue;
                }
                
                if (!productCode || !productCode.toString().trim()) {
                    console.log(`Skipping row ${i + 1}: Missing product code/SKU`);
                    skippedCount++;
                    errors.push(`Row ${i + 1}: Missing product code/SKU for "${productName}"`);
                    continue;
                }
                
                if (isNaN(price) || price <= 0) {
                    console.log(`Skipping row ${i + 1}: Invalid price (${price})`);
                    skippedCount++;
                    errors.push(`Row ${i + 1}: Invalid price for "${productName}"`);
                    continue;
                }
                
                const trimmedProductName = productName.toString().trim();
                const trimmedProductCode = productCode.toString().trim();
                const trimmedCategory = category ? category.toString().trim() : 'General';
                const trimmedDescription = description ? description.toString().trim() : null;
                const validMRP = isNaN(mrp) || mrp <= 0 ? price : mrp;
                const validStock = isNaN(stockQuantity) ? 0 : stockQuantity;
                const trimmedDistributorId = distributorIdFromExcel ? distributorIdFromExcel.toString().trim() : distributorId;
                
                const existingProduct = await collections.product.findOne({ 
                    $or: [
                        { productName: trimmedProductName, distributorId: trimmedDistributorId },
                        { sku: trimmedProductCode }
                    ]
                });
                
                if (existingProduct) {
                    if (updateExisting === 'true') {
                        const updateResult = await collections.product.updateOne(
                            { _id: existingProduct._id },
                            {
                                $set: {
                                    productName: trimmedProductName,
                                    mrp: validMRP,
                                    price: price,
                                    category: trimmedCategory,
                                    stock: validStock,
                                    stockQuantity: validStock,
                                    description: trimmedDescription,
                                    updatedAt: new Date().toISOString(),
                                    updatedBy: createdBy || 'import'
                                }
                            }
                        );
                        updatedCount++;
                        console.log(`Updated product ${updatedCount}: ${trimmedProductName}`);
                    } else {
                        console.log(`Skipping row ${i + 1}: Product "${trimmedProductName}" already exists`);
                        skippedCount++;
                        errors.push(`Row ${i + 1}: Product "${trimmedProductName}" already exists (use updateExisting=true to update)`);
                    }
                    continue;
                }
                
                const product = {
                    productName: trimmedProductName,
                    sku: trimmedProductCode,
                    mrp: validMRP,
                    price: price,
                    category: trimmedCategory,
                    stock: validStock,
                    stockQuantity: validStock,
                    description: trimmedDescription,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                    createdBy: createdBy || 'import',
                    distributorId: trimmedDistributorId,
                    isActive: true,
                    images: [],
                    tags: []
                };
                
                await collections.product.insertOne(product);
                importedCount++;
                console.log(`Imported product ${importedCount}: ${trimmedProductName}`);
                
            } catch (rowError) {
                console.error(`Error importing row ${i + 1}:`, rowError);
                skippedCount++;
                errors.push(`Row ${i + 1}: ${rowError.message}`);
            }
        }
        
        if (fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
        
        console.log(`Import completed: ${importedCount} imported, ${updatedCount} updated, ${skippedCount} skipped`);
        
        res.json({
            success: true,
            message: `Imported ${importedCount} products, updated ${updatedCount} products successfully. Skipped ${skippedCount} entries.`,
            importedCount: importedCount,
            updatedCount: updatedCount,
            skippedCount: skippedCount,
            errors: errors.length > 0 ? errors.slice(0, 10) : []
        });
        
    } catch (error) {
        console.error('Error importing products:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            try {
                fs.unlinkSync(req.file.path);
            } catch (unlinkError) {
                console.error('Error cleaning up file:', unlinkError);
            }
        }
        res.status(500).json({ error: error.message, success: false });
    }
});

// ==================== CUSTOMER APIs ====================

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

app.get('/api/customers/id/:id', async (req, res) => {
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

app.put('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updated_at = new Date().toISOString();
        
        delete updateData._id;
        delete updateData.created_at;
        
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

app.delete('/api/customers/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const customer = await collections.customer.findOne({ _id: new ObjectId(id) });
        if (customer) {
            const orders = await collections.order.find({ customerId: customer.customer_id }).toArray();
            if (orders.length > 0) {
                return res.status(400).json({ error: 'Cannot delete customer with existing orders. Please delete orders first or deactivate the customer.' });
            }
        }
        
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

// ==================== SEARCH API ====================
app.get('/api/search/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const { query } = req.query;
        
        console.log(`Global search - Distributor: ${distributorId}, Query: ${query}`);
        
        if (!query || query.trim().length < 2) {
            return res.json({ products: [], customers: [], orders: [] });
        }
        
        const searchTerm = query.trim();
        const searchRegex = new RegExp(searchTerm, 'i');
        
        const products = await collections.product.find({
            distributorId: distributorId,
            isActive: true,
            $or: [
                { productName: searchRegex },
                { sku: searchRegex },
                { category: searchRegex }
            ]
        }).limit(20).toArray();
        
        const customers = await collections.customer.find({
            distributor_id: distributorId,
            $or: [
                { name: searchRegex },
                { customer_id: searchRegex },
                { phone: searchRegex },
                { area: searchRegex }
            ]
        }).limit(20).toArray();
        
        const orders = await collections.order.find({
            distributor_id: distributorId,
            $or: [
                { orderNumber: searchRegex },
                { customerName: searchRegex },
                { salesmanName: searchRegex }
            ]
        }).limit(20).sort({ createdAt: -1 }).toArray();
        
        console.log(`Search results - Products: ${products.length}, Customers: ${customers.length}, Orders: ${orders.length}`);
        
        res.json({
            products: products,
            customers: customers,
            orders: orders
        });
    } catch (error) {
        console.error('Error searching:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== FREE API FOR AREAS AND ROUTES ====================

app.get('/api/areas', async (req, res) => {
    try {
        const { city } = req.query;
        
        let areas = [];
        
        if (!city || city === '') {
            areas = [
                'Mumbai', 'Delhi', 'Bangalore', 'Hyderabad', 'Ahmedabad', 
                'Chennai', 'Kolkata', 'Pune', 'Jaipur', 'Lucknow',
                'Nagpur', 'Indore', 'Bhopal', 'Vadodara', 'Ludhiana',
                'Agra', 'Nashik', 'Ranchi', 'Chandigarh', 'Mysore'
            ];
        } else {
            const areaMap = {
                'pune': ['Shivajinagar', 'Kothrud', 'Hinjewadi', 'Pimpri-Chinchwad', 'Hadapsar', 'Viman Nagar', 'Koregaon Park', 'Baner', 'Aundh', 'Wakad'],
                'mumbai': ['Andheri', 'Bandra', 'Dadar', 'Navi Mumbai', 'Thane', 'Powai', 'Malad', 'Borivali', 'Colaba', 'Juhu'],
                'delhi': ['Connaught Place', 'South Delhi', 'North Delhi', 'East Delhi', 'West Delhi', 'Noida', 'Gurgaon', 'Dwarka', 'Rohini'],
                'bangalore': ['Indiranagar', 'Koramangala', 'Whitefield', 'Electronic City', 'Jayanagar', 'Marathahalli', 'BTM Layout'],
                'hyderabad': ['Gachibowli', 'Hitech City', 'Jubilee Hills', 'Banjara Hills', 'Secunderabad', 'Kukatpally'],
                'chennai': ['T Nagar', 'Adyar', 'Velachery', 'Tambaram', 'Anna Nagar', 'Porur', 'OMR'],
                'kolkata': ['Salt Lake', 'Park Street', 'New Town', 'Howrah', 'Dum Dum', 'Ballygunge'],
                'ahmedabad': ['Satellite', 'Navrangpura', 'Maninagar', 'Vastrapur', 'Bodakdev', 'Chandkheda'],
                'jaipur': ['Malviya Nagar', 'Vaishali Nagar', 'Tonk Road', 'Ajmer Road', 'Sanganer'],
                'lucknow': ['Hazratganj', 'Gomti Nagar', 'Aliganj', 'Indira Nagar', 'Chinhat']
            };
            
            const cityLower = city.toLowerCase();
            if (areaMap[cityLower]) {
                areas = areaMap[cityLower];
            } else {
                areas = [`${city} Area 1`, `${city} Area 2`, `${city} Area 3`, `${city} Area 4`, `${city} Area 5`];
            }
        }
        
        res.json({ areas: areas });
    } catch (error) {
        console.error('Error fetching areas:', error);
        res.json({ areas: [] });
    }
});

app.get('/api/sub-areas', async (req, res) => {
    try {
        const { area } = req.query;
        
        const routeMap = {
            'Shivajinagar': ['FC Road', 'Jangli Maharaj Road', 'Shanipar', 'Laxmi Road', 'Tilak Road'],
            'Kothrud': ['Karve Road', 'Paud Road', 'Mayur Colony', 'Ideal Colony', 'Vanaz', 'Kothrud Depot'],
            'Hinjewadi': ['Phase 1', 'Phase 2', 'Phase 3', 'Maan Road', 'Hinjewadi Lake', 'Rajiv Gandhi Infotech Park'],
            'Pimpri-Chinchwad': ['Pimpri Camp', 'Chinchwad Station', 'Akurdi', 'Ravet', 'Nigdi', 'Talwade'],
            'Hadapsar': ['Magarpatta', 'Mundhwa', 'Kharadi', 'Keshav Nagar', 'Handewadi Road', 'Pune-Solapur Road'],
            'Viman Nagar': ['Airport Road', 'Kalyani Nagar', 'Nagar Road', 'Sakore Nagar', 'Clover Park'],
            'Koregaon Park': ['North Main Road', 'Lane 5', 'Lane 7', 'Mundhwa Road', 'Bund Garden Road'],
            'Baner': ['Balewadi High Street', 'Baner Road', 'Pashan', 'Sus Road', 'Baner Gaon', 'Bhumkar Chowk'],
            'Aundh': ['DP Road', 'ITI Road', 'Medipoint', 'Sangvi', 'Aundh Gaon', 'Bremen Chowk'],
            'Wakad': ['Datta Mandir Road', 'Bhumkar Chowk', 'Mhalunge', 'Wakad Bridge', 'Hinjewadi-Wakad Road'],
            'Warje': ['Warje Malwadi', 'Karve Nagar', 'Erandwane', 'Nal Stop', 'Kothrud-Warje Road'],
            'Kalewadi': ['Kalewadi Phata', 'Kalewadi Chowk', 'Rahatani', 'Pimple Saudagar', 'Pimple Gurav'],
            'Moshi': ['Moshi Bazar Peth', 'Moshi Chowk', 'Chikhali', 'Bhosari', 'Dighi'],
            'Karvenagar': ['Karve Putala', 'Sahakar Nagar', 'Katraj-Karvenagar Road', 'Deshmukh Nagar']
        };
        
        let routes = [];
        if (area && routeMap[area]) {
            routes = routeMap[area];
        } else if (area) {
            routes = [`${area} Main Road`, `${area} Market Area`, `${area} Residential Area`, `${area} Industrial Area`];
        }
        
        res.json({ routes: routes });
    } catch (error) {
        console.error('Error fetching sub-areas:', error);
        res.json({ routes: [] });
    }
});

// ==================== PASSWORD CHANGE APIs ====================

app.post('/api/change-password', async (req, res) => {
    try {
        const { userId, currentPassword, newPassword, requestingUserId, requestingUserRole } = req.body;
        
        if (!userId || !newPassword) {
            return res.status(400).json({ error: 'User ID and new password are required' });
        }
        
        let targetUser = null;
        
        try {
            if (ObjectId.isValid(userId) && userId.length === 24) {
                targetUser = await collections.register.findOne({ _id: new ObjectId(userId) });
            }
        } catch (err) {
            console.log('Invalid ObjectId format, trying other methods');
        }
        
        if (!targetUser) {
            targetUser = await collections.register.findOne({ salesman_id: userId });
        }
        if (!targetUser) {
            targetUser = await collections.register.findOne({ distributor_id: userId });
        }
        if (!targetUser) {
            targetUser = await collections.register.findOne({ email: userId });
        }
        if (!targetUser) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        let requestingUserObj = null;
        try {
            if (requestingUserId && ObjectId.isValid(requestingUserId) && requestingUserId.length === 24) {
                requestingUserObj = await collections.register.findOne({ _id: new ObjectId(requestingUserId) });
            }
        } catch (err) {
            console.log('Invalid requestingUserId format');
        }
        
        if (!requestingUserObj && requestingUserId) {
            requestingUserObj = await collections.register.findOne({ salesman_id: requestingUserId });
        }
        if (!requestingUserObj && requestingUserId) {
            requestingUserObj = await collections.register.findOne({ distributor_id: requestingUserId });
        }
        
        if (requestingUserRole === 'distributor') {
            if (targetUser.distributor_id !== requestingUserObj?.distributor_id) {
                return res.status(403).json({ error: 'You can only change passwords for users under your distributor account' });
            }
        } else if (requestingUserRole === 'salesman') {
            if (targetUser._id.toString() !== requestingUserId && targetUser.salesman_id !== requestingUserId) {
                return res.status(403).json({ error: 'You can only change your own password' });
            }
            if (!currentPassword) {
                return res.status(400).json({ error: 'Current password is required to change your password' });
            }
            const isValidPassword = await bcrypt.compare(currentPassword, targetUser.password);
            if (!isValidPassword) {
                return res.status(401).json({ error: 'Current password is incorrect' });
            }
        } else {
            return res.status(403).json({ error: 'Permission denied' });
        }
        
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(newPassword, saltRounds);
        
        const result = await collections.register.updateOne(
            { _id: targetUser._id },
            { $set: { password: hashedPassword, updatedAt: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'User not found' });
        }
        
        res.json({ success: true, message: 'Password changed successfully' });
    } catch (error) {
        console.error('Error changing password:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/users-under-distributor/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        
        const users = await collections.register.find({ 
            distributor_id: distributorId,
            isActive: true
        }).toArray();
        
        const formattedUsers = users.map(user => ({
            id: user._id,
            name: user.fullName,
            email: user.email,
            role: user.role,
            salesman_id: user.salesman_id
        }));
        
        res.json({ users: formattedUsers });
    } catch (error) {
        console.error('Error fetching users:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== NOTIFICATION APIs ====================

async function createOrderNotification(order, distributorId, salesmanId, salesmanName) {
    try {
        if (!order.salesman_id || order.created_by_type === 'distributor') {
            console.log(`Skipping notification - order created by distributor or no salesman associated`);
            return;
        }
        
        let actualSalesmanName = salesmanName;
        if (!actualSalesmanName && salesmanId) {
            const salesman = await collections.salesman.findOne({ salesman_id: salesmanId });
            if (salesman) {
                actualSalesmanName = salesman.name;
            } else {
                const registerUser = await collections.register.findOne({ salesman_id: salesmanId });
                if (registerUser) {
                    actualSalesmanName = registerUser.fullName;
                }
            }
        }
        
        const finalSalesmanName = actualSalesmanName || salesmanId || 'Salesman';
        
        const notification = {
            _id: new ObjectId(),
            distributor_id: distributorId,
            order_id: order.orderNumber,
            order_number: order.orderNumber,
            customer_name: order.customerName,
            salesman_name: finalSalesmanName,
            amount: order.grand_total || order.totalAmount,
            message: `New order #${order.orderNumber} created by salesman ${finalSalesmanName} for customer ${order.customerName}`,
            type: 'new_order',
            isRead: false,
            createdAt: new Date().toISOString(),
            order_data: order,
            redirect_to: `/orders/${order.orderNumber}`
        };
        
        await collections.notification.insertOne(notification);
        console.log(`Notification created for distributor ${distributorId} about order ${order.orderNumber} from salesman ${finalSalesmanName}`);
        
        return notification;
    } catch (error) {
        console.error('Error creating notification:', error);
    }
}

async function createOrderUpdateNotification(order, distributorId, salesmanId, salesmanName, action, oldData = null) {
    try {
        let actionMessage = '';
        switch(action) {
            case 'edit':
                actionMessage = `edited order #${order.orderNumber}`;
                break;
            case 'delete':
                actionMessage = `deleted order #${order.orderNumber}`;
                break;
            default:
                actionMessage = `updated order #${order.orderNumber}`;
        }
        
        let actualSalesmanName = salesmanName;
        if (!actualSalesmanName && salesmanId) {
            const salesman = await collections.salesman.findOne({ salesman_id: salesmanId });
            if (salesman) {
                actualSalesmanName = salesman.name;
            } else {
                const registerUser = await collections.register.findOne({ salesman_id: salesmanId });
                if (registerUser) {
                    actualSalesmanName = registerUser.fullName;
                }
            }
        }
        
        const finalSalesmanName = actualSalesmanName || salesmanId || 'Salesman';
        
        const notification = {
            _id: new ObjectId(),
            distributor_id: distributorId,
            order_id: order.orderNumber,
            order_number: order.orderNumber,
            customer_name: order.customerName,
            salesman_name: finalSalesmanName,
            amount: order.grand_total || order.totalAmount,
            message: `Salesman ${finalSalesmanName} ${actionMessage} for customer ${order.customerName}`,
            type: `order_${action}`,
            isRead: false,
            createdAt: new Date().toISOString(),
            order_data: order,
            old_data: oldData,
            redirect_to: `/orders/${order.orderNumber}`
        };
        
        await collections.notification.insertOne(notification);
        console.log(`Order update notification created for distributor ${distributorId}`);
        
        return notification;
    } catch (error) {
        console.error('Error creating order update notification:', error);
    }
}

async function createPaymentNotification(order, paymentAmount, paymentMode, salesmanId, salesmanName, distributorId) {
    try {
        console.log(`Creating payment notification: Order ${order.orderNumber}, Amount ₹${paymentAmount}, Distributor ${distributorId}, Salesman ${salesmanName}`);
        
        const notification = {
            _id: new ObjectId(),
            distributor_id: distributorId,
            order_id: order.orderNumber,
            order_number: order.orderNumber,
            customer_name: order.customerName,
            salesman_name: salesmanName,
            amount: paymentAmount,
            message: `💰 Payment of ₹${paymentAmount} collected by salesman ${salesmanName} for order #${order.orderNumber} via ${paymentMode}`,
            type: 'payment_collected',
            isRead: false,
            createdAt: new Date().toISOString(),
            payment_amount: paymentAmount,
            payment_mode: paymentMode,
            redirect_to: `/orders/${order.orderNumber}`
        };
        
        const result = await collections.notification.insertOne(notification);
        console.log(`✅ Payment notification created for distributor ${distributorId} with ID: ${result.insertedId}`);
        
        return notification;
    } catch (error) {
        console.error('Error creating payment notification:', error);
    }
}

app.get('/api/notifications/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const notifications = await collections.notification
            .find({ distributor_id: distributorId })
            .sort({ createdAt: -1 })
            .toArray();
        res.json(notifications);
    } catch (error) {
        console.error('Error fetching notifications:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/notifications/unread-count/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const count = await collections.notification.countDocuments({ 
            distributor_id: distributorId, 
            isRead: false 
        });
        res.json({ count });
    } catch (error) {
        console.error('Error fetching unread count:', error);
        res.status(500).json({ error: error.message });
    }
});

app.put('/api/notifications/:notificationId/read', async (req, res) => {
    try {
        const { notificationId } = req.params;
        const result = await collections.notification.updateOne(
            { _id: new ObjectId(notificationId) },
            { $set: { isRead: true, readAt: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Notification not found' });
        }
        
        const notification = await collections.notification.findOne({ _id: new ObjectId(notificationId) });
        
        res.json({ 
            success: true, 
            message: 'Notification marked as read',
            redirect_to: notification?.redirect_to || null
        });
    } catch (error) {
        console.error('Error marking notification as read:', error);
        res.status(500).json({ error: error.message });
    }
});

app.put('/api/notifications/mark-all-read/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        await collections.notification.updateMany(
            { distributor_id: distributorId, isRead: false },
            { $set: { isRead: true, readAt: new Date().toISOString() } }
        );
        res.json({ success: true, message: 'All notifications marked as read' });
    } catch (error) {
        console.error('Error marking all notifications as read:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== DISTRIBUTOR APIs ====================

app.get('/api/distributors/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const distributor = await collections.distributor.findOne({ distributor_id: distributorId });
        if (!distributor) {
            return res.status(404).json({ error: 'Distributor not found' });
        }
        res.json(distributor);
    } catch (error) {
        console.error('Error fetching distributor:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/distributors', async (req, res) => {
    try {
        const distributors = await collections.distributor.find({}).toArray();
        res.json(distributors);
    } catch (error) {
        console.error('Error fetching distributors:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== CUSTOMER APIs (continued) ====================

app.post('/api/customers', async (req, res) => {
    try {
        const customerData = req.body;
        
        if (!customerData.customer_id) {
            const count = await collections.customer.countDocuments({ distributor_id: customerData.distributor_id });
            customerData.customer_id = `GK${String(count + 1).padStart(4, '0')}`;
        }
        
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

// ==================== PRODUCT APIs ====================

app.post('/api/products', async (req, res) => {
    try {
        const productData = req.body;
        
        productData.createdAt = productData.createdAt || new Date().toISOString();
        productData.updatedAt = new Date().toISOString();
        productData.isActive = productData.isActive !== undefined ? productData.isActive : true;
        
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

app.get('/api/products/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        console.log(`Fetching products for distributor: ${distributorId}`);
        
        const products = await collections.product
            .find({ distributorId: distributorId, isActive: true })
            .sort({ createdAt: -1 })
            .toArray();
        
        // Ensure price and mrp are returned as-is without rounding
        products.forEach(product => {
            // Keep original decimal values
            if (product.price) product.price = parseFloat(product.price);
            if (product.mrp) product.mrp = parseFloat(product.mrp);
        });
        
        console.log(`Found ${products.length} products for distributor ${distributorId}`);
        res.json(products);
    } catch (error) {
        console.error('Error fetching products:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/products/id/:id', async (req, res) => {
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

app.put('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updatedAt = new Date().toISOString();
        
        // Ensure price and mrp are stored as-is without rounding
        if (updateData.price) {
            updateData.price = parseFloat(updateData.price);
        }
        if (updateData.mrp) {
            updateData.mrp = parseFloat(updateData.mrp);
        }
        
        delete updateData._id;
        
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

app.put('/api/products/:id/stock', async (req, res) => {
    try {
        const { id } = req.params;
        const { stockReduction, newStock } = req.body;
        
        if (!ObjectId.isValid(id)) {
            return res.status(400).json({ error: 'Invalid product ID format' });
        }
        
        const product = await collections.product.findOne({ _id: new ObjectId(id) });
        if (!product) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        let updatedStock;
        if (newStock !== undefined) {
            updatedStock = newStock;
        } else {
            const currentStock = product.stock || 0;
            const soldQuantity = stockReduction || 0;
            updatedStock = currentStock - soldQuantity;
            if (updatedStock < 0) {
                updatedStock = 0;
            }
            console.log(`Stock calculation: Current: ${currentStock}, Sold: ${soldQuantity}, New: ${updatedStock}`);
        }
        
        const result = await collections.product.updateOne(
            { _id: new ObjectId(id) },
            { $set: { stock: updatedStock, updatedAt: new Date().toISOString() } }
        );
        
        console.log(`Product stock updated: ${product.productName || product.name} - Old stock: ${product.stock || 0}, Sold: ${stockReduction || 0}, New stock: ${updatedStock}`);
        
        res.json({ success: true, newStock: updatedStock });
    } catch (error) {
        console.error('Error updating product stock:', error);
        res.status(500).json({ error: error.message });
    }
});

app.delete('/api/products/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const product = await collections.product.findOne({ _id: new ObjectId(id) });
        if (product) {
            const orders = await collections.order.find({ 
                'items.productId': id,
                'items.sku': product.sku 
            }).toArray();
            
            if (orders.length > 0) {
                return res.status(400).json({ error: 'Cannot delete product that is used in existing orders. Deactivate the product instead.' });
            }
        }
        
        const result = await collections.product.updateOne(
            { _id: new ObjectId(id) },
            { $set: { isActive: false, updatedAt: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Product not found' });
        }
        
        res.json({ success: true, message: 'Product deactivated successfully' });
    } catch (error) {
        console.error('Error deleting product:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== SALESMAN APIs ====================

app.post('/api/salesmen', async (req, res) => {
    try {
        const salesmanData = req.body;
        
        if (!validateAlphabetOnly(salesmanData.name)) {
            return res.status(400).json({ error: 'Name should contain only alphabets and spaces' });
        }
        
        if (!validateMobileNumber(salesmanData.phone)) {
            return res.status(400).json({ error: 'Phone number must be exactly 10 digits' });
        }
        
        if (!salesmanData.salesman_id) {
            const count = await collections.salesman.countDocuments({ distributor_id: salesmanData.distributor_id });
            salesmanData.salesman_id = `SM${String(count + 1).padStart(4, '0')}`;
        }
        
        salesmanData.created_at = salesmanData.created_at || new Date().toISOString();
        salesmanData.updated_at = new Date().toISOString();
        salesmanData.status = salesmanData.status || 'active';
        salesmanData.achieved_amount = salesmanData.achieved_amount || 0;
        salesmanData.performance_metrics = salesmanData.performance_metrics || {};
        salesmanData.bank_details = salesmanData.bank_details || {};
        salesmanData.documents = salesmanData.documents || {};
        salesmanData.notes = salesmanData.notes || '';
        
        const existingUser = await collections.register.findOne({ 
            email: salesmanData.email, 
            role: 'salesman' 
        });
        
        if (existingUser) {
            return res.status(400).json({ error: 'A salesman with this email already exists' });
        }
        
        const defaultPassword = `${salesmanData.name.substring(0, 3).toLowerCase()}${salesmanData.phone.substring(6)}`;
        
        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(defaultPassword, saltRounds);
        
        const permissions = salesmanData.permissions || {
            canAddProduct: false,
            canEditProduct: false,
            canDeleteProduct: false,
            canAddCustomer: false,
            canEditCustomer: false,
            canDeleteCustomer: false,
            canViewOrders: true,
            canCreateOrder: true,
            canCollectPayment: true,
            canEditOrder: true,
            canDeleteOrder: true
        };
        
        const loginEntry = {
            fullName: salesmanData.name,
            email: salesmanData.email,
            phoneNumber: salesmanData.phone,
            password: hashedPassword,
            role: 'salesman',
            distributor_id: salesmanData.distributor_id,
            salesman_id: salesmanData.salesman_id,
            accountType: 'SalesmanUser',
            createdAt: new Date(),
            isActive: true,
            defaultPassword: defaultPassword,
            permissions: permissions
        };
        
        const loginResult = await collections.register.insertOne(loginEntry);
        
        const result = await collections.salesman.insertOne(salesmanData);
        
        res.json({ 
            success: true, 
            message: `Salesman added successfully. Default password: ${defaultPassword}`,
            defaultPassword: defaultPassword,
            _id: result.insertedId,
            login_id: loginResult.insertedId,
            ...salesmanData
        });
    } catch (error) {
        console.error('Error adding salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

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

app.get('/api/salesmen/id/:id', async (req, res) => {
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

app.get('/api/salesmen/by-id/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        const salesman = await collections.salesman.findOne({ salesman_id: salesmanId });
        if (!salesman) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        res.json(salesman);
    } catch (error) {
        console.error('Error fetching salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

app.put('/api/salesmen/:id', async (req, res) => {
    try {
        const { id } = req.params;
        const updateData = req.body;
        updateData.updated_at = new Date().toISOString();
        
        delete updateData._id;
        
        const result = await collections.salesman.updateOne(
            { _id: new ObjectId(id) },
            { $set: updateData }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        if (updateData.name || updateData.email || updateData.phone) {
            const salesman = await collections.salesman.findOne({ _id: new ObjectId(id) });
            if (salesman && salesman.salesman_id) {
                const registerUpdate = {};
                if (updateData.name) registerUpdate.fullName = updateData.name;
                if (updateData.email) registerUpdate.email = updateData.email;
                if (updateData.phone) registerUpdate.phoneNumber = updateData.phone;
                
                if (Object.keys(registerUpdate).length > 0) {
                    await collections.register.updateOne(
                        { salesman_id: salesman.salesman_id },
                        { $set: registerUpdate }
                    );
                }
            }
        }
        
        res.json({ success: true, message: 'Salesman updated successfully' });
    } catch (error) {
        console.error('Error updating salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

app.delete('/api/salesmen/:id', async (req, res) => {
    try {
        const { id } = req.params;
        
        const salesman = await collections.salesman.findOne({ _id: new ObjectId(id) });
        if (salesman) {
            const orders = await collections.order.find({ salesman_id: salesman.salesman_id }).toArray();
            if (orders.length > 0) {
                return res.status(400).json({ error: 'Cannot delete salesman with existing orders. Deactivate the salesman instead.' });
            }
        }
        
        const result = await collections.salesman.updateOne(
            { _id: new ObjectId(id) },
            { $set: { status: 'inactive', updated_at: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        await collections.register.updateOne(
            { salesman_id: (await collections.salesman.findOne({ _id: new ObjectId(id) }))?.salesman_id },
            { $set: { isActive: false } }
        );
        
        res.json({ success: true, message: 'Salesman deactivated successfully' });
    } catch (error) {
        console.error('Error deleting salesman:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== SALESMAN PERMISSION APIs ====================

app.put('/api/salesmen/permissions/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        const { permissions } = req.body;
        
        await collections.salesman.updateOne(
            { salesman_id: salesmanId },
            { $set: { permissions: permissions, updated_at: new Date().toISOString() } }
        );
        
        const result = await collections.register.updateOne(
            { salesman_id: salesmanId, role: 'salesman' },
            { $set: { permissions: permissions, updated_at: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        res.json({ success: true, message: 'Permissions updated successfully' });
    } catch (error) {
        console.error('Error updating permissions:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/salesmen/permissions/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        const salesman = await collections.register.findOne({ 
            salesman_id: salesmanId, 
            role: 'salesman' 
        });
        
        if (!salesman) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        res.json({ permissions: salesman.permissions || {} });
    } catch (error) {
        console.error('Error fetching permissions:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/salesman-data/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        
        const salesman = await collections.register.findOne({ 
            salesman_id: salesmanId, 
            role: 'salesman' 
        });
        
        if (!salesman) {
            return res.status(404).json({ error: 'Salesman not found' });
        }
        
        const distributorId = salesman.distributor_id;
        console.log(`Salesman ${salesmanId} belongs to distributor: ${distributorId}`);
        
        const salesmanDetails = await collections.salesman.findOne({ salesman_id: salesmanId });
        const salesmanName = salesmanDetails?.name || salesman.fullName || salesmanId;
        
        const customers = await collections.customer
            .find({ distributor_id: distributorId })
            .sort({ created_at: -1 })
            .toArray();
        
        console.log(`Found ${customers.length} customers for distributor ${distributorId}`);
        
        const products = await collections.product
            .find({ distributorId: distributorId, isActive: true })
            .sort({ createdAt: -1 })
            .toArray();
        
        console.log(`Found ${products.length} products for distributor ${distributorId}`);
        
        const orders = await collections.order
            .find({ salesman_id: salesmanId })
            .sort({ createdAt: -1 })
            .toArray();
        
        const permissions = salesman.permissions || {
            canAddProduct: false,
            canEditProduct: false,
            canDeleteProduct: false,
            canAddCustomer: false,
            canEditCustomer: false,
            canDeleteCustomer: false,
            canViewOrders: true,
            canCreateOrder: true,
            canCollectPayment: true,
            canEditOrder: true,
            canDeleteOrder: true
        };
        
        const collectionHistory = await collections.collectionHistory
            .find({ 'salesman_details.id': salesmanId })
            .sort({ collection_date: -1 })
            .toArray();
        
        console.log(`Found ${collectionHistory.length} collection history records for salesman ${salesmanId}`);
        
        const totalCollection = collectionHistory.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
        
        const payments = await collections.payment
            .find({ 'salesman_details.id': salesmanId })
            .sort({ created_at: -1 })
            .toArray();
        
        res.json({
            customers: customers,
            products: products,
            orders: orders,
            permissions: permissions,
            salesmanName: salesmanName,
            collectionHistory: collectionHistory,
            payments: payments,
            totalCollection: totalCollection
        });
    } catch (error) {
        console.error('Error fetching salesman data:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== ORDER APIs ====================

app.post('/api/orders', async (req, res) => {
    try {
        const orderData = req.body;
        
        const orderNumber = `ORD${Date.now()}`;
        orderData.orderNumber = orderNumber;
        orderData.order_id = orderNumber;
        orderData.createdAt = new Date().toISOString();
        orderData.updatedAt = new Date().toISOString();
        orderData.order_date = new Date().toISOString();
        
        let distributorId = orderData.distributor_id || orderData.distributorId;
        
        if (!distributorId && orderData.salesman_id) {
            const salesman = await collections.salesman.findOne({ salesman_id: orderData.salesman_id });
            if (salesman && salesman.distributor_id) {
                distributorId = salesman.distributor_id;
            } else {
                const registerUser = await collections.register.findOne({ salesman_id: orderData.salesman_id });
                if (registerUser && registerUser.distributor_id) {
                    distributorId = registerUser.distributor_id;
                }
            }
        }
        
        orderData.distributor_id = distributorId;
        orderData.distributorId = distributorId;
        
        // FIXED: Store customer_id as string from customer object
        if (orderData.customerId) {
            const customer = await getCustomerById(orderData.customerId);
            if (customer && customer.customer_id) {
                orderData.customerId = customer.customer_id;
            }
        }
        
        // FIXED: Store salesman_id correctly - ensure we use the actual salesman_id from the salesman object
        if (orderData.salesman_id) {
            const salesman = await getSalesmanById(orderData.salesman_id);
            if (salesman && salesman.salesman_id) {
                orderData.salesman_id = salesman.salesman_id;
                console.log(`✅ Salesman ID set to: ${orderData.salesman_id}`);
            } else {
                console.log(`⚠️ Salesman not found for ID: ${orderData.salesman_id}, keeping original value: ${orderData.salesman_id}`);
            }
        }
        
        // FIXED: Process order items to ensure MRP is saved
        if (orderData.items && Array.isArray(orderData.items) && orderData.items.length > 0) {
            orderData.items = await processOrderItems(orderData.items);
            console.log(`Processed ${orderData.items.length} order items with MRP values`);
        }
        
        orderData.created_by_type = orderData.created_by_type || (orderData.salesman_id ? 'salesman' : 'distributor');
        
        orderData.status = orderData.status || 'pending';
        orderData.payment_status = orderData.payment_status || 'pending';
        orderData.paidAmount = orderData.paidAmount || 0;
        orderData.dueAmount = orderData.grand_total || 0;
        
        const result = await collections.order.insertOne(orderData);
        
        console.log(`Order created: ${orderNumber} with ID: ${result.insertedId}`);
        console.log(`Order created by: ${orderData.created_by_type}, Distributor ID: ${distributorId}, Salesman ID: ${orderData.salesman_id || 'N/A'}, Customer ID: ${orderData.customerId}`);
        
        if (orderData.items && Array.isArray(orderData.items) && orderData.items.length > 0) {
            for (const item of orderData.items) {
                try {
                    let product = null;
                    if (item.productId && ObjectId.isValid(item.productId)) {
                        product = await collections.product.findOne({ _id: new ObjectId(item.productId) });
                    } else if (item.sku) {
                        product = await collections.product.findOne({ sku: item.sku });
                    } else if (item.product_id) {
                        product = await collections.product.findOne({ _id: new ObjectId(item.product_id) });
                    }
                    
                    if (product) {
                        const quantitySold = parseInt(item.quantity) || parseInt(item.qty) || 0;
                        const currentStock = product.stock || 0;
                        const newStock = currentStock - quantitySold;
                        const finalStock = newStock < 0 ? 0 : newStock;
                        
                        await collections.product.updateOne(
                            { _id: product._id },
                            { 
                                $set: { 
                                    stock: finalStock, 
                                    updatedAt: new Date().toISOString() 
                                } 
                            }
                        );
                        console.log(`Stock updated for product ${product.productName || product.name}: ${currentStock} -> ${finalStock} (Sold: ${quantitySold})`);
                    } else {
                        console.warn(`Product not found for stock update: ${item.productId || item.sku}`);
                    }
                } catch (stockError) {
                    console.error(`Error updating stock for product ${item.productId}:`, stockError);
                }
            }
        }
        
        if (distributorId && orderData.salesman_id && orderData.created_by_type === 'salesman') {
            let salesmanName = orderData.salesmanName;
            if (!salesmanName && orderData.salesman_id) {
                const salesman = await collections.salesman.findOne({ salesman_id: orderData.salesman_id });
                if (salesman) {
                    salesmanName = salesman.name;
                } else {
                    const registerUser = await collections.register.findOne({ salesman_id: orderData.salesman_id });
                    if (registerUser) {
                        salesmanName = registerUser.fullName;
                    }
                }
            }
            await createOrderNotification(orderData, distributorId, orderData.salesman_id, salesmanName);
        } else {
            console.log(`No notification created for order ${orderNumber} - created by distributor or no salesman associated`);
        }
        
        res.json({ 
            success: true, 
            message: 'Order created successfully',
            _id: result.insertedId,
            orderNumber: orderNumber
        });
    } catch (error) {
        console.error('Error creating order:', error);
        res.status(500).json({ error: error.message });
    }
});

app.put('/api/orders/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        const updateData = req.body;
        
        let order = null;
        if (ObjectId.isValid(orderId)) {
            order = await collections.order.findOne({ _id: new ObjectId(orderId) });
        }
        if (!order) {
            order = await collections.order.findOne({ orderNumber: orderId });
        }
        
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        const oldItems = order.items || [];
        const newItems = updateData.items || [];
        
        for (const item of oldItems) {
            try {
                let product = null;
                if (item.productId && ObjectId.isValid(item.productId)) {
                    product = await collections.product.findOne({ _id: new ObjectId(item.productId) });
                } else if (item.sku) {
                    product = await collections.product.findOne({ sku: item.sku });
                }
                
                if (product) {
                    const oldQuantity = parseInt(item.quantity) || parseInt(item.qty) || 0;
                    const currentStock = product.stock || 0;
                    const newStock = currentStock + oldQuantity;
                    
                    await collections.product.updateOne(
                        { _id: product._id },
                        { $set: { stock: newStock, updatedAt: new Date().toISOString() } }
                    );
                    console.log(`Stock restored for product ${product.productName}: +${oldQuantity}, New stock: ${newStock}`);
                }
            } catch (stockError) {
                console.error(`Error restoring stock for product ${item.productId}:`, stockError);
            }
        }
        
        // Process new items to ensure MRP is included
        let processedNewItems = newItems;
        if (newItems && newItems.length > 0) {
            processedNewItems = await processOrderItems(newItems);
            updateData.items = processedNewItems;
        }
        
        for (const item of processedNewItems) {
            try {
                let product = null;
                if (item.productId && ObjectId.isValid(item.productId)) {
                    product = await collections.product.findOne({ _id: new ObjectId(item.productId) });
                } else if (item.sku) {
                    product = await collections.product.findOne({ sku: item.sku });
                }
                
                if (product) {
                    const newQuantity = parseInt(item.quantity) || parseInt(item.qty) || 0;
                    const currentStock = product.stock || 0;
                    const newStock = currentStock - newQuantity;
                    const finalStock = newStock < 0 ? 0 : newStock;
                    
                    await collections.product.updateOne(
                        { _id: product._id },
                        { $set: { stock: finalStock, updatedAt: new Date().toISOString() } }
                    );
                    console.log(`Stock deducted for product ${product.productName}: -${newQuantity}, New stock: ${finalStock}`);
                }
            } catch (stockError) {
                console.error(`Error deducting stock for product ${item.productId}:`, stockError);
            }
        }
        
        updateData.updatedAt = new Date().toISOString();
        delete updateData._id;
        
        const result = await collections.order.updateOne(
            { _id: order._id },
            { $set: updateData }
        );
        
        if (order.distributor_id && order.salesman_id) {
            let salesmanName = updateData.salesmanName || order.salesmanName;
            if (!salesmanName && order.salesman_id) {
                const salesman = await collections.salesman.findOne({ salesman_id: order.salesman_id });
                if (salesman) {
                    salesmanName = salesman.name;
                }
            }
            await createOrderUpdateNotification(updateData, order.distributor_id, order.salesman_id, salesmanName, 'edit', order);
        }
        
        res.json({ success: true, message: 'Order updated successfully' });
    } catch (error) {
        console.error('Error updating order:', error);
        res.status(500).json({ error: error.message });
    }
});

app.delete('/api/orders/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        
        let order = null;
        if (ObjectId.isValid(orderId)) {
            order = await collections.order.findOne({ _id: new ObjectId(orderId) });
        }
        if (!order) {
            order = await collections.order.findOne({ orderNumber: orderId });
        }
        
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        if (order.paidAmount > 0) {
            return res.status(400).json({ error: 'Cannot delete order with payments already made. Please refund the payment first.' });
        }
        
        if (order.items && Array.isArray(order.items)) {
            for (const item of order.items) {
                try {
                    let product = null;
                    if (item.productId && ObjectId.isValid(item.productId)) {
                        product = await collections.product.findOne({ _id: new ObjectId(item.productId) });
                    } else if (item.sku) {
                        product = await collections.product.findOne({ sku: item.sku });
                    }
                    
                    if (product) {
                        const quantity = parseInt(item.quantity) || parseInt(item.qty) || 0;
                        const currentStock = product.stock || 0;
                        const newStock = currentStock + quantity;
                        
                        await collections.product.updateOne(
                            { _id: product._id },
                            { $set: { stock: newStock, updatedAt: new Date().toISOString() } }
                        );
                        console.log(`Stock restored for product ${product.productName}: +${quantity}, New stock: ${newStock}`);
                    }
                } catch (stockError) {
                    console.error(`Error restoring stock for product ${item.productId}:`, stockError);
                }
            }
        }
        
        await collections.notification.deleteMany({ order_id: order.orderNumber });
        
        const result = await collections.order.deleteOne({ _id: order._id });
        
        if (result.deletedCount === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        if (order.distributor_id && order.salesman_id) {
            let salesmanName = order.salesmanName;
            if (!salesmanName && order.salesman_id) {
                const salesman = await collections.salesman.findOne({ salesman_id: order.salesman_id });
                if (salesman) {
                    salesmanName = salesman.name;
                }
            }
            await createOrderUpdateNotification(order, order.distributor_id, order.salesman_id, salesmanName, 'delete');
        }
        
        res.json({ success: true, message: 'Order deleted successfully' });
    } catch (error) {
        console.error('Error deleting order:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/salesman/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        
        const orders = await collections.order
            .find({ salesman_id: salesmanId })
            .sort({ createdAt: -1 })
            .toArray();
        res.json(orders);
    } catch (error) {
        console.error('Error fetching orders:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/distributor/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const { customerName, salesmanId, startDate, endDate, search } = req.query;
        
        let query = { distributor_id: distributorId };
        
        if (search && search.trim()) {
            const searchTerm = search.trim();
            query.$or = [
                { orderNumber: { $regex: searchTerm, $options: 'i' } },
                { customerName: { $regex: searchTerm, $options: 'i' } },
                { customerPhone: { $regex: searchTerm, $options: 'i' } },
                { salesmanName: { $regex: searchTerm, $options: 'i' } },
                { areaName: { $regex: searchTerm, $options: 'i' } }
            ];
        }
        
        if (customerName && customerName.trim()) {
            query.customerName = { $regex: customerName, $options: 'i' };
        }
        
        if (salesmanId && salesmanId.trim() && salesmanId !== 'all') {
            query.salesman_id = salesmanId;
        }
        
        if (startDate || endDate) {
            query.order_date = {};
            if (startDate) {
                query.order_date.$gte = new Date(startDate).toISOString();
            }
            if (endDate) {
                query.order_date.$lte = new Date(endDate).toISOString();
            }
        }
        
        const orders = await collections.order
            .find(query)
            .sort({ createdAt: -1 })
            .toArray();
        res.json(orders);
    } catch (error) {
        console.error('Error fetching orders:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== ORDER DOWNLOAD WITH STATUS TRACKING ====================

// New endpoint to update order status to 'downloaded'
app.put('/api/orders/status/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { status, orderNumber } = req.body;
        
        console.log(`Updating order status - Order ID: ${orderId}, New Status: ${status}, Order Number: ${orderNumber}`);
        
        let order = null;
        
        // Try to find order by _id first
        if (ObjectId.isValid(orderId)) {
            order = await collections.order.findOne({ _id: new ObjectId(orderId) });
        }
        
        // If not found, try by orderNumber
        if (!order && orderNumber) {
            order = await collections.order.findOne({ orderNumber: orderNumber });
        }
        
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        const result = await collections.order.updateOne(
            { _id: order._id },
            { 
                $set: { 
                    status: status,
                    downloadedAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString()
                } 
            }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        console.log(`✅ Order ${order.orderNumber} status updated to '${status}'`);
        
        res.json({ 
            success: true, 
            message: `Order status updated to ${status} successfully`,
            orderId: order.orderNumber
        });
    } catch (error) {
        console.error('Error updating order status:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/download/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const { startDate, endDate, filterType } = req.query;
        
        let query = { distributor_id: distributorId };
        
        let startDateTime, endDateTime;
        const now = new Date();
        
        if (filterType === 'today') {
            startDateTime = new Date(now.setHours(0, 0, 0, 0));
            endDateTime = new Date(now.setHours(23, 59, 59, 999));
            query.order_date = {
                $gte: startDateTime.toISOString(),
                $lte: endDateTime.toISOString()
            };
        } else if (filterType === 'yesterday') {
            const yesterday = new Date(now);
            yesterday.setDate(yesterday.getDate() - 1);
            startDateTime = new Date(yesterday.setHours(0, 0, 0, 0));
            endDateTime = new Date(yesterday.setHours(23, 59, 59, 999));
            query.order_date = {
                $gte: startDateTime.toISOString(),
                $lte: endDateTime.toISOString()
            };
        } else if (filterType === 'lastWeek') {
            const lastWeek = new Date(now);
            lastWeek.setDate(lastWeek.getDate() - 7);
            startDateTime = new Date(lastWeek.setHours(0, 0, 0, 0));
            endDateTime = new Date(now.setHours(23, 59, 59, 999));
            query.order_date = {
                $gte: startDateTime.toISOString(),
                $lte: endDateTime.toISOString()
            };
        } else if (startDate || endDate) {
            query.order_date = {};
            if (startDate) {
                query.order_date.$gte = new Date(startDate).toISOString();
            }
            if (endDate) {
                query.order_date.$lte = new Date(endDate).toISOString();
            }
        }
        
        const orders = await collections.order
            .find(query)
            .sort({ order_date: -1 })
            .toArray();
        
        if (!orders || orders.length === 0) {
            return res.status(404).json({ error: 'No orders found for the selected date range' });
        }
        
        const excelData = [];
        
        for (const order of orders) {
            let salesmanCode = order.salesman_id || '';
            let salesmanName = order.salesmanName || '';
            
            if (!salesmanName && order.salesman_id) {
                const salesman = await collections.salesman.findOne({ salesman_id: order.salesman_id });
                if (salesman) {
                    salesmanName = salesman.name;
                } else {
                    const registerUser = await collections.register.findOne({ salesman_id: order.salesman_id });
                    if (registerUser) {
                        salesmanName = registerUser.fullName;
                    }
                }
            }
            
            if (order.items && Array.isArray(order.items) && order.items.length > 0) {
                for (const item of order.items) {
                    let mrpValue = item.mrp || 0;
                    if (!mrpValue && item.productId) {
                        try {
                            let product = null;
                            if (ObjectId.isValid(item.productId)) {
                                product = await collections.product.findOne({ _id: new ObjectId(item.productId) });
                            } else if (item.sku) {
                                product = await collections.product.findOne({ sku: item.sku });
                            }
                            if (product && product.mrp) {
                                mrpValue = product.mrp;
                            } else if (product && product.price) {
                                mrpValue = product.price;
                            }
                        } catch (err) {
                            console.log('Error fetching product MRP:', err);
                        }
                    }
                    
                    const quantity = parseInt(item.quantity) || parseInt(item.qty) || 0;
                    const rate = parseFloat(item.rate) || parseFloat(item.price) || 0;
                    const netAmount = quantity * rate;
                    
                    excelData.push({
                        'Order No': order.orderNumber,
                        'Order Date': new Date(order.order_date).toLocaleDateString('en-IN'),
                        'Party code': order.customerId || order.customer_id || '',
                        'Party name': order.customerName || '',
                        'Product code': item.productCode || item.sku || item.productId || '',
                        'Product name': item.productName || item.name || '',
                        'MRP': mrpValue,
                        'QTY': quantity,
                        'Rate': rate,
                        'Unit': 'PCS',
                        'SSMcode': salesmanCode,
                        'Salesman name': salesmanName,
                        'Net amount': netAmount
                    });
                }
            } else {
                excelData.push({
                    'Order No': order.orderNumber,
                    'Order Date': new Date(order.order_date).toLocaleDateString('en-IN'),
                    'Party code': order.customerId || order.customer_id || '',
                    'Party name': order.customerName || '',
                    'Product code': '',
                    'Product name': '',
                    'MRP': 0,
                    'QTY': 0,
                    'Rate': 0,
                    'Unit': 'PCS',
                    'SSMcode': salesmanCode,
                    'Salesman name': salesmanName,
                    'Net amount': order.grand_total || order.order_total || 0
                });
            }
        }
        
        const worksheet = XLSX.utils.json_to_sheet(excelData);
        
        const colWidths = [
            { wch: 15 }, { wch: 12 }, { wch: 15 }, { wch: 25 }, { wch: 15 },
            { wch: 30 }, { wch: 10 }, { wch: 8 }, { wch: 10 }, { wch: 6 }, 
            { wch: 12 }, { wch: 20 }, { wch: 12 }
        ];
        worksheet['!cols'] = colWidths;
        
        const workbook = XLSX.utils.book_new();
        XLSX.utils.book_append_sheet(workbook, worksheet, 'Orders');
        
        const excelBuffer = XLSX.write(workbook, { type: 'buffer', bookType: 'xlsx' });
        
        res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        res.setHeader('Content-Disposition', `attachment; filename=orders_${distributorId}_${Date.now()}.xlsx`);
        
        res.send(excelBuffer);
        
    } catch (error) {
        console.error('Error downloading orders:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/customer/:customerId', async (req, res) => {
    try {
        const { customerId } = req.params;
        
        const orders = await collections.order
            .find({ customerId: customerId })
            .sort({ createdAt: -1 })
            .toArray();
        res.json(orders);
    } catch (error) {
        console.error('Error fetching orders by customer:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/customer/:customerId/last', async (req, res) => {
    try {
        const { customerId } = req.params;
        
        const order = await collections.order
            .find({ customerId: customerId })
            .sort({ createdAt: -1 })
            .limit(1)
            .toArray();
        
        res.json(order.length > 0 ? order[0] : null);
    } catch (error) {
        console.error('Error fetching last order:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/products/:productId/last-sale', async (req, res) => {
    try {
        const { productId } = req.params;
        
        const order = await collections.order
            .find({ 'items.productId': productId })
            .sort({ createdAt: -1 })
            .limit(1)
            .toArray();
        
        if (order.length > 0) {
            const lastOrder = order[0];
            const item = lastOrder.items.find(i => i.productId === productId);
            res.json({
                order: lastOrder,
                quantity: item?.quantity || 0,
                customerName: lastOrder.customerName,
                orderNumber: lastOrder.orderNumber
            });
        } else {
            res.json(null);
        }
    } catch (error) {
        console.error('Error fetching last sale:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/orders/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        
        let order = null;
        if (ObjectId.isValid(orderId)) {
            order = await collections.order.findOne({ _id: new ObjectId(orderId) });
        }
        
        if (!order) {
            order = await collections.order.findOne({ orderNumber: orderId });
        }
        
        if (!order) {
            return res.status(404).json({ error: 'Order not found' });
        }
        res.json(order);
    } catch (error) {
        console.error('Error fetching order:', error);
        res.status(500).json({ error: error.message });
    }
});

app.put('/api/orders/:orderId/status', async (req, res) => {
    try {
        const { orderId } = req.params;
        const { status } = req.body;
        
        const result = await collections.order.updateOne(
            { orderNumber: orderId },
            { $set: { status: status, updatedAt: new Date().toISOString() } }
        );
        
        if (result.matchedCount === 0) {
            return res.status(404).json({ error: 'Order not found' });
        }
        
        res.json({ success: true, message: 'Order status updated successfully' });
    } catch (error) {
        console.error('Error updating order status:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== PAYMENT APIs - FIXED ====================

app.get('/api/payments', async (req, res) => {
    try {
        const payments = await collections.payment
            .find({})
            .sort({ created_at: -1 })
            .toArray();
        res.json(payments);
    } catch (error) {
        console.error('Error fetching payments:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/payments/distributor/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        const payments = await collections.payment
            .find({ 'collected_by.id': distributorId })
            .sort({ created_at: -1 })
            .toArray();
        res.json(payments);
    } catch (error) {
        console.error('Error fetching payments:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/payments/salesman/:salesmanId', async (req, res) => {
    try {
        const { salesmanId } = req.params;
        const payments = await collections.payment
            .find({ 'salesman_details.id': salesmanId })
            .sort({ created_at: -1 })
            .toArray();
        res.json(payments);
    } catch (error) {
        console.error('Error fetching payments:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/payments/order/:orderId', async (req, res) => {
    try {
        const { orderId } = req.params;
        const payments = await collections.payment
            .find({ 'order_details.order_id': orderId })
            .sort({ created_at: -1 })
            .toArray();
        res.json(payments);
    } catch (error) {
        console.error('Error fetching payments by order:', error);
        res.status(500).json({ error: error.message });
    }
});

// FIXED: Payment recording with correct IDs and cheque/UPI details
app.post('/api/orders/:orderId/payment', upload.single('paymentPhoto'), async (req, res) => {
    try {
        const { orderId } = req.params;
        
        // Log all fields received for debugging
        console.log('=== PAYMENT REQUEST RECEIVED ===');
        console.log('Order ID:', orderId);
        console.log('Body fields:', req.body);
        console.log('File received:', req.file ? req.file.originalname : 'No file');
        
        // Extract fields from request body - support both form-data and JSON
        const amount = req.body.amount;
        const paymentMode = req.body.paymentMode;
        const reference = req.body.reference;
        const collectedBy = req.body.collectedBy;
        const collectedByName = req.body.collectedByName;
        const collectedByType = req.body.collectedByType;
        const salesmanId = req.body.salesmanId;
        const salesmanName = req.body.salesmanName;
        const chequeNumber = req.body.chequeNumber;
        const chequeDate = req.body.chequeDate;
        const bankName = req.body.bankName;
        const upiType = req.body.upiType;
        const transactionNumber = req.body.transactionNumber;
        const remark = req.body.remark;
        
        console.log('Extracted payment details:', {
            amount, paymentMode, chequeNumber, chequeDate, bankName, upiType, transactionNumber, remark
        });
        
        let order = null;
        
        if (ObjectId.isValid(orderId)) {
            order = await collections.order.findOne({ _id: new ObjectId(orderId) });
        }
        
        if (!order) {
            order = await collections.order.findOne({ orderNumber: orderId });
        }
        
        if (!order) {
            console.error(`Order not found for ID: ${orderId}`);
            return res.status(404).json({ error: 'Order not found' });
        }
        
        console.log(`Order found: ${order.orderNumber}`);
        
        // FIXED: Get the actual customer to get the correct customer_id (string like GK30800)
        let actualCustomerId = order.customerId;
        let actualCustomerName = order.customerName;
        
        const customer = await getCustomerById(order.customerId);
        if (customer) {
            actualCustomerId = customer.customer_id || order.customerId;
            actualCustomerName = customer.name || order.customerName;
            console.log(`Found customer: ${actualCustomerName} with ID: ${actualCustomerId}`);
        } else {
            console.log(`Customer not found for ID: ${order.customerId}, using order values`);
        }
        
        // FIXED: Get the actual salesman details
        let actualSalesmanId = salesmanId || collectedBy;
        let actualSalesmanName = salesmanName || collectedByName;
        
        if (salesmanId) {
            const salesman = await getSalesmanById(salesmanId);
            if (salesman) {
                actualSalesmanId = salesman.salesman_id || salesmanId;
                actualSalesmanName = salesman.name || salesmanName;
                console.log(`Found salesman: ${actualSalesmanName} with ID: ${actualSalesmanId}`);
            } else {
                const registerUser = await getRegisterUserById(salesmanId);
                if (registerUser && registerUser.salesman_id) {
                    actualSalesmanId = registerUser.salesman_id;
                    actualSalesmanName = registerUser.fullName || salesmanName;
                    console.log(`Found salesman in register: ${actualSalesmanName} with ID: ${actualSalesmanId}`);
                } else {
                    console.log(`Salesman not found for ID: ${salesmanId}, using provided values`);
                }
            }
        }
        
        // FIXED: Get distributor ID for collected_by.id if needed
        let actualCollectedById = collectedBy;
        let actualCollectedByName = collectedByName;
        
        if (collectedByType === 'distributor' && collectedBy) {
            const distributor = await getDistributorById(collectedBy);
            if (distributor) {
                actualCollectedById = distributor.distributor_id || collectedBy;
                actualCollectedByName = distributor.name || collectedByName;
                console.log(`Found distributor: ${actualCollectedByName} with ID: ${actualCollectedById}`);
            }
        }
        
        const paymentAmount = parseFloat(amount);
        const newPaidAmount = (order.paidAmount || 0) + paymentAmount;
        const newDueAmount = order.grand_total - newPaidAmount;
        
        const collectionId = generateCollectionId();
        
        // FIXED: Properly save UPI and Cheque details with all required fields
        let paymentModesDetails = {};
        let photoPath = null;
        
        if (req.file) {
            photoPath = req.file.path;
            console.log(`Payment photo saved at: ${photoPath}`);
        }
        
        // Normalize payment mode
        const normalizedPaymentMode = paymentMode ? paymentMode.toLowerCase() : '';
        
        if (normalizedPaymentMode === 'cheque') {
            paymentModesDetails = {
                mode: 'Cheque',
                cheque_number: chequeNumber || null,
                bank_name: bankName || null,
                cheque_date: chequeDate || null,
                reference_number: reference || chequeNumber || null,
                photo_path: photoPath
            };
            console.log(`Saving Cheque details: Number=${chequeNumber}, Bank=${bankName}, Date=${chequeDate}`);
        } else if (normalizedPaymentMode === 'upi') {
            paymentModesDetails = {
                mode: 'UPI',
                reference_number: transactionNumber || reference || null,
                upi_type: upiType || null,
                transaction_number: transactionNumber || null,
                photo_path: photoPath
            };
            console.log(`Saving UPI details: Type=${upiType}, Transaction=${transactionNumber}`);
        } else if (normalizedPaymentMode === 'cash') {
            paymentModesDetails = {
                mode: 'Cash',
                reference_number: null,
                photo_path: photoPath
            };
        } else {
            paymentModesDetails = {
                mode: paymentMode || 'Unknown',
                reference_number: reference || null,
                photo_path: photoPath
            };
        }
        
        // FIXED: Payment record with correct IDs and all payment details
        const paymentRecord = {
            collection_id: collectionId,
            collection_date: new Date().toISOString(),
            customer_id: actualCustomerId,
            customer_name: actualCustomerName,
            amount_collected: paymentAmount,
            payment_mode: paymentMode,
            collected_by: {
                type: collectedByType || (salesmanId ? 'salesman' : 'distributor'),
                id: actualSalesmanId || actualCollectedById || collectedBy,
                name: actualSalesmanName || actualCollectedByName || collectedByName,
                time: new Date().toISOString()
            },
            salesman_details: actualSalesmanId ? {
                id: actualSalesmanId,
                name: actualSalesmanName,
                time: new Date().toISOString()
            } : null,
            distributor_details: collectedByType === 'distributor' ? {
                id: actualCollectedById,
                name: actualCollectedByName,
                time: new Date().toISOString()
            } : null,
            payment_modes_details: paymentModesDetails,
            // FIXED: Store cheque and UPI specific fields at top level for easy access
            cheque_number: (normalizedPaymentMode === 'cheque') ? (chequeNumber || null) : null,
            bank_name: (normalizedPaymentMode === 'cheque') ? (bankName || null) : null,
            cheque_date: (normalizedPaymentMode === 'cheque') ? (chequeDate || null) : null,
            upi_type: (normalizedPaymentMode === 'upi') ? (upiType || null) : null,
            transaction_number: (normalizedPaymentMode === 'upi') ? (transactionNumber || null) : null,
            reference_number: reference || chequeNumber || transactionNumber || null,
            photo_path: photoPath,
            remark: remark || null,
            order_details: {
                order_id: order.orderNumber,
                order_amount: order.grand_total,
                previous_paid: order.paidAmount || 0,
                previous_due: order.dueAmount || order.grand_total,
                status: newDueAmount <= 0 ? 'completed' : 'partial',
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            }
        };
        
        console.log('Payment record to save:', JSON.stringify(paymentRecord, null, 2));
        
        const paymentResult = await collections.payment.insertOne(paymentRecord);
        console.log(`✅ Payment recorded with ID: ${paymentResult.insertedId}, Collection ID: ${collectionId}`);
        console.log(`   Customer ID saved: ${actualCustomerId}`);
        console.log(`   Salesman ID saved: ${actualSalesmanId}`);
        console.log(`   Payment Mode: ${paymentMode}`);
        console.log(`   Cheque Number: ${chequeNumber}`);
        console.log(`   Bank Name: ${bankName}`);
        console.log(`   Cheque Date: ${chequeDate}`);
        
        // Create collection history entry with correct IDs
        await createCollectionHistory(
            order, 
            paymentAmount, 
            paymentMode, 
            actualSalesmanId || actualCollectedById || collectedBy, 
            actualSalesmanName || actualCollectedByName || collectedByName, 
            salesmanId ? 'salesman' : 'distributor', 
            actualSalesmanId, 
            actualSalesmanName
        );
        
        const updateData = { 
            paidAmount: newPaidAmount,
            dueAmount: newDueAmount,
            payment_method: paymentMode,
            paymentReference: reference || chequeNumber || transactionNumber,
            collectedBy: actualSalesmanId || actualCollectedById || collectedBy,
            paymentCollectedBySalesman: actualSalesmanId || null,
            paymentCollectedAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            payment_status: newDueAmount <= 0 ? 'paid' : 'partial',
            status: newDueAmount <= 0 ? 'delivered' : order.status
        };
        
        // FIXED: Store cheque and UPI details in order as well
        if (normalizedPaymentMode === 'cheque') {
            updateData.chequeNumber = chequeNumber;
            updateData.chequeDate = chequeDate;
            updateData.bankName = bankName;
        } else if (normalizedPaymentMode === 'upi') {
            updateData.upiType = upiType;
            updateData.transactionNumber = transactionNumber;
            if (photoPath) {
                updateData.paymentPhoto = photoPath;
            }
        } else if (photoPath) {
            updateData.paymentPhoto = photoPath;
        }
        
        const result = await collections.order.updateOne(
            { _id: order._id },
            { $set: updateData }
        );
        
        console.log(`Order ${order.orderNumber} updated with payment info`);
        
        // Create payment notification for distributor when salesman collects payment
        if (order.distributor_id && actualSalesmanId && actualSalesmanId !== order.distributor_id) {
            await createPaymentNotification(order, paymentAmount, paymentMode, actualSalesmanId, actualSalesmanName, order.distributor_id);
            console.log(`✅ Payment notification sent to distributor ${order.distributor_id} for collection of ₹${paymentAmount} from salesman ${actualSalesmanName}`);
        } else if (order.distributor_id && actualCollectedById && actualCollectedById !== order.distributor_id) {
            await createPaymentNotification(order, paymentAmount, paymentMode, actualCollectedById, actualCollectedByName, order.distributor_id);
            console.log(`✅ Payment notification sent to distributor ${order.distributor_id} for collection of ₹${paymentAmount}`);
        }
        
        res.json({ 
            success: true, 
            message: 'Payment recorded successfully',
            payment_id: paymentResult.insertedId,
            collection_id: collectionId,
            new_due_amount: newDueAmount,
            order_updated: true,
            customer_id_saved: actualCustomerId,
            salesman_id_saved: actualSalesmanId,
            payment_details: {
                mode: paymentMode,
                cheque_number: chequeNumber,
                bank_name: bankName,
                cheque_date: chequeDate,
                upi_type: upiType,
                transaction_number: transactionNumber
            }
        });
    } catch (error) {
        console.error('Error recording payment:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/customers/:customerId/outstanding', async (req, res) => {
    try {
        const { customerId } = req.params;
        
        const customer = await getCustomerById(customerId);
        const actualCustomerId = customer ? customer.customer_id : customerId;
        
        const orders = await collections.order
            .find({ 
                customerId: actualCustomerId,
                status: { $ne: 'cancelled' }
            })
            .toArray();
        
        const totalDue = orders.reduce((sum, order) => sum + (order.dueAmount || 0), 0);
        
        res.json({ outstanding: totalDue });
    } catch (error) {
        console.error('Error fetching outstanding:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/banks', (req, res) => {
    res.json({ banks: INDIAN_BANKS });
});

app.get('/api/upi-types', (req, res) => {
    res.json({ upiTypes: UPI_APPS });
});

// ==================== DASHBOARD STATS APIs ====================
app.get('/api/dashboard/stats/:distributorId', async (req, res) => {
    try {
        const { distributorId } = req.params;
        
        const totalSalesmen = await collections.salesman.countDocuments({ distributor_id: distributorId });
        
        const totalCustomers = await collections.customer.countDocuments({ distributor_id: distributorId });
        
        const totalProducts = await collections.product.countDocuments({ distributorId: distributorId, isActive: true });
        
        const orders = await collections.order.find({ distributor_id: distributorId }).toArray();
        const totalOrders = orders.length;
        
        const totalOrderValue = orders.reduce((sum, order) => sum + (order.grand_total || 0), 0);
        
        const collectionsData = await collections.collectionHistory.find({ distributor_id: distributorId }).toArray();
        const totalCollected = collectionsData.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
        const totalTransactions = collectionsData.length;
        
        const totalOutstanding = orders.reduce((sum, order) => sum + (order.dueAmount || 0), 0);
        
        const recentOrders = await collections.order
            .find({ distributor_id: distributorId })
            .sort({ createdAt: -1 })
            .limit(10)
            .toArray();
        
        const recentCollections = await collections.collectionHistory
            .find({ distributor_id: distributorId })
            .sort({ collection_date: -1 })
            .limit(10)
            .toArray();
        
        const salesmanPerformance = [];
        const salesmen = await collections.salesman.find({ distributor_id: distributorId }).toArray();
        
        for (const salesman of salesmen) {
            const salesmanOrders = orders.filter(o => o.salesman_id === salesman.salesman_id);
            const salesmanCollections = collectionsData.filter(c => c.salesman_details?.id === salesman.salesman_id);
            
            const totalSales = salesmanOrders.reduce((sum, o) => sum + (o.grand_total || 0), 0);
            const totalCollection = salesmanCollections.reduce((sum, c) => sum + (c.amount_collected || 0), 0);
            const collectionRatio = totalSales > 0 ? (totalCollection / totalSales) * 100 : 0;
            
            salesmanPerformance.push({
                salesman_id: salesman.salesman_id,
                name: salesman.name,
                total_sales: totalSales,
                total_collection: totalCollection,
                collection_ratio: collectionRatio,
                orders_count: salesmanOrders.length,
                collections_count: salesmanCollections.length
            });
        }
        
        salesmanPerformance.sort((a, b) => b.collection_ratio - a.collection_ratio);
        
        res.json({
            summary: {
                total_salesmen: totalSalesmen,
                total_customers: totalCustomers,
                total_products: totalProducts,
                total_orders: totalOrders,
                total_order_value: totalOrderValue,
                total_collected: totalCollected,
                total_transactions: totalTransactions,
                total_outstanding: totalOutstanding
            },
            recent_orders: recentOrders,
            recent_collections: recentCollections,
            salesman_performance: salesmanPerformance
        });
    } catch (error) {
        console.error('Error fetching dashboard stats:', error);
        res.status(500).json({ error: error.message });
    }
});

// ==================== AUTH APIs ====================

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

app.post('/api/register', async (req, res) => {
    try {
        console.log('Received registration request:', req.body);
        
        const { fullName, email, phoneNumber, password, role, accountType, createdAt, isActive } = req.body;
        
        if (!fullName || !email || !phoneNumber || !password || !role) {
            return res.status(400).json({ 
                message: 'Missing required fields',
                error: 'All fields are required'
            });
        }
        
        if (!validateAlphabetOnly(fullName)) {
            return res.status(400).json({ 
                message: 'Name should contain only alphabets and spaces' 
            });
        }
        
        if (!validateEmail(email)) {
            return res.status(400).json({ 
                message: 'Invalid email format. Please enter a valid email address (e.g., name@example.com)' 
            });
        }
        
        if (!validateMobileNumber(phoneNumber)) {
            return res.status(400).json({ 
                message: 'Invalid mobile number. Mobile number must be exactly 10 digits' 
            });
        }
        
        const normalizedEmail = normalizeEmail(email);
        const existingUser = await collections.register.findOne({ email: normalizedEmail, role });
        if (existingUser) {
            return res.status(400).json({ 
                message: 'User with this email already registered for this role' 
            });
        }

        const saltRounds = 10;
        const hashedPassword = await bcrypt.hash(password, saltRounds);
        
        let distributorId = null;
        if (role === 'distributor') {
            distributorId = generateDistributorId();
            
            const distributorDoc = {
                distributor_id: distributorId,
                name: fullName,
                email: normalizedEmail,
                phone: phoneNumber,
                created_at: new Date().toISOString(),
                isActive: true
            };
            
            await collections.distributor.insertOne(distributorDoc);
            console.log(`Created distributor with ID: ${distributorId}`);
        }
        
        const userDocument = {
            fullName: fullName,
            email: normalizedEmail,
            phoneNumber: phoneNumber,
            password: hashedPassword,
            role: role,
            distributor_id: distributorId,
            accountType: accountType || 'PortalUser',
            createdAt: createdAt ? new Date(createdAt) : new Date(),
            isActive: isActive !== undefined ? isActive : true
        };
        
        console.log('Attempting to insert user:', { ...userDocument, password: '[HIDDEN]' });
        
        const result = await collections.register.insertOne(userDocument);
        
        console.log('User inserted successfully with ID:', result.insertedId);
        
        res.status(201).json({ 
            message: 'Registration successful', 
            userId: result.insertedId,
            distributor_id: distributorId
        });
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ 
            message: 'Internal server error', 
            error: error.message 
        });
    }
});

app.post('/api/login', async (req, res) => {
    try {
        const { email, password } = req.body;
        
        console.log('Login attempt for:', { email });
        
        if (!validateEmail(email)) {
            return res.status(401).json({ message: 'Invalid email format' });
        }
        
        const normalizedEmail = normalizeEmail(email);
        
        const user = await collections.register.findOne({ email: normalizedEmail });
        
        if (!user) {
            return res.status(401).json({ message: 'Invalid credentials. Email or password incorrect.' });
        }
        
        if (user.isActive === false) {
            return res.status(401).json({ message: 'Account is deactivated. Please contact administrator.' });
        }
        
        const isValidPassword = await bcrypt.compare(password, user.password);
        
        if (!isValidPassword) {
            return res.status(401).json({ message: 'Invalid credentials. Email or password incorrect.' });
        }

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

app.post('/api/logout', async (req, res) => {
    try {
        res.json({ 
            success: true, 
            message: 'Logout successful' 
        });
    } catch (error) {
        console.error('Error during logout:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

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

app.listen(PORT, async () => {
    await connectToMongoDB();
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`API endpoints available at http://localhost:${PORT}/api`);
    console.log(`Logo available at http://localhost:${PORT}/isset/image/TotalSolution.png`);
    console.log(`\nAPI Endpoints:`);
    console.log(`\nAuth:`);
    console.log(`  POST /api/login - User login`);
    console.log(`  POST /api/logout - User logout`);
    console.log(`  POST /api/register - User registration`);
    console.log(`\nSearch:`);
    console.log(`  GET /api/search/:distributorId?query=term - Global search for products, customers, orders`);
    console.log(`\nImport Master Data:`);
    console.log(`  POST /api/import/customers - Import customers from Excel (with updateExisting flag)`);
    console.log(`  POST /api/import/products - Import products from Excel (with updateExisting flag)`);
    console.log(`\nDistributors:`);
    console.log(`  GET /api/distributors - Get all distributors`);
    console.log(`  GET /api/distributors/:distributorId - Get distributor by ID`);
    console.log(`\nCustomers:`);
    console.log(`  GET /api/customers/:distributorId - Get all customers`);
    console.log(`  POST /api/customers - Add new customer`);
    console.log(`  GET /api/customers/id/:id - Get single customer`);
    console.log(`  PUT /api/customers/:id - Update customer (ALL fields editable for imported customers)`);
    console.log(`  DELETE /api/customers/:id - Delete customer (only if no orders exist)`);
    console.log(`\nProducts:`);
    console.log(`  GET /api/products/:distributorId - Get all products (includes MRP field)`);
    console.log(`  POST /api/products - Add new product (includes MRP)`);
    console.log(`  GET /api/products/id/:id - Get single product`);
    console.log(`  PUT /api/products/:id - Update product`);
    console.log(`  DELETE /api/products/:id - Delete product (deactivate if used in orders)`);
    console.log(`  PUT /api/products/:id/stock - Update product stock (correct calculation)`);
    console.log(`  GET /api/products/:productId/last-sale - Get last sale for product`);
    console.log(`\nSalesmen:`);
    console.log(`  GET /api/salesmen/:distributorId - Get all salesmen`);
    console.log(`  POST /api/salesmen - Add new salesman`);
    console.log(`  GET /api/salesmen/id/:id - Get single salesman`);
    console.log(`  GET /api/salesmen/by-id/:salesmanId - Get salesman by salesman_id`);
    console.log(`  PUT /api/salesmen/:id - Update salesman`);
    console.log(`  DELETE /api/salesmen/:id - Delete salesman (deactivate if has orders)`);
    console.log(`\nPermissions:`);
    console.log(`  GET /api/salesmen/permissions/:salesmanId - Get permissions`);
    console.log(`  PUT /api/salesmen/permissions/:salesmanId - Update permissions`);
    console.log(`\nSalesman Data:`);
    console.log(`  GET /api/salesman-data/:salesmanId - Get all data for salesman (includes totalCollection from collection history)`);
    console.log(`\nOrders:`);
    console.log(`  POST /api/orders - Create order (auto-updates stock and saves MRP)`);
    console.log(`  PUT /api/orders/:orderId - Edit order (adjusts stock and sends notification)`);
    console.log(`  DELETE /api/orders/:orderId - Delete order (restores stock and sends notification)`);
    console.log(`  GET /api/orders/salesman/:salesmanId - Get orders by salesman`);
    console.log(`  GET /api/orders/distributor/:distributorId - Get orders by distributor`);
    console.log(`  GET /api/orders/download/:distributorId - Download orders as Excel with MRP and QTY columns`);
    console.log(`  PUT /api/orders/status/:orderId - Update order status to 'downloaded' (for tracking downloaded orders)`);
    console.log(`  GET /api/orders/customer/:customerId - Get orders by customer`);
    console.log(`  GET /api/orders/customer/:customerId/last - Get last order by customer`);
    console.log(`  GET /api/orders/:orderId - Get single order`);
    console.log(`  PUT /api/orders/:orderId/status - Update order status`);
    console.log(`\nPayments & Collection History:`);
    console.log(`  POST /api/orders/:orderId/payment - Record payment with file upload (sends notification to distributor)`);
    console.log(`  GET /api/payments - Get all payments`);
    console.log(`  GET /api/payments/distributor/:distributorId - Get payments for distributor`);
    console.log(`  GET /api/payments/salesman/:salesmanId - Get payments for salesman`);
    console.log(`  GET /api/collection-history/distributor/:distributorId - Get collection history for distributor (from mas_payment collection)`);
    console.log(`  GET /api/collection-history/salesman/:salesmanId - Get collection history for salesman (from mas_payment collection)`);
    console.log(`  GET /api/collection-history/reconcile/:distributorId - Reconcile collections with expected amount`);
    console.log(`  GET /api/customers/:customerId/outstanding - Get customer outstanding balance`);
    console.log(`  GET /api/banks - Get list of Indian banks`);
    console.log(`  GET /api/upi-types - Get list of UPI types`);
    console.log(`\nDashboard:`);
    console.log(`  GET /api/dashboard/stats/:distributorId - Get dashboard statistics with salesman performance (Revenue = sum of order amounts, Collection = sum of collection history)`);
    console.log(`\nNotifications:`);
    console.log(`  GET /api/notifications/:distributorId - Get notifications for distributor`);
    console.log(`  GET /api/notifications/unread-count/:distributorId - Get unread count`);
    console.log(`  PUT /api/notifications/:notificationId/read - Mark notification as read (returns redirect_to URL)`);
    console.log(`  PUT /api/notifications/mark-all-read/:distributorId - Mark all as read`);
    console.log(`\nAreas & Routes:`);
    console.log(`  GET /api/areas - Get major Indian cities and areas`);
    console.log(`  GET /api/sub-areas - Get real sub-areas/routes for selected area`);
    console.log(`\nPassword Change:`);
    console.log(`  POST /api/change-password - Change user password`);
    console.log(`  GET /api/users-under-distributor/:distributorId - Get users under distributor`);
    console.log(`\n✅ NEW FEATURE ADDED:`);
    console.log(`  1) ✅ Added PUT /api/orders/status/:orderId endpoint to update order status to 'downloaded'`);
    console.log(`  2) ✅ Orders now have a 'status' field that can be set to 'downloaded' when orders are downloaded to desktop`);
    console.log(`  3) ✅ Added 'downloadedAt' timestamp to track when order was downloaded`);
    console.log(`  4) ✅ Added index on 'status' field for faster queries`);
    console.log(`\n✅ FIXED: Salesman ID is now properly stored in orders - using the actual salesman_id from mas_salesman collection`);
});