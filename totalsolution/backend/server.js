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
  NOTIFICATION: 'mas_notification'
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
        
        console.log('Connected to MongoDB successfully');
        console.log(`Database: ${DB_NAME}`);
        
        await collections.register.createIndex({ email: 1, role: 1 }, { unique: true });
        await collections.customer.createIndex({ customer_id: 1 }, { unique: true });
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
        await collections.payment.createIndex({ collection_id: 1 }, { unique: true });
        await collections.payment.createIndex({ customer_id: 1 });
        await collections.payment.createIndex({ 'collected_by.id': 1 });
        await collections.notification.createIndex({ distributor_id: 1 });
        await collections.notification.createIndex({ isRead: 1 });
        await collections.notification.createIndex({ createdAt: -1 });
        
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

// ==================== IMPORT MASTER DATA APIs ====================

// Import customers from Excel
app.post('/api/import/customers', excelUpload.single('file'), async (req, res) => {
    try {
        const { distributorId, createdBy } = req.body;
        
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }
        
        if (!distributorId) {
            return res.status(400).json({ error: 'Distributor ID is required' });
        }
        
        const workbook = XLSX.readFile(req.file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        if (!data || data.length === 0) {
            return res.status(400).json({ error: 'No data found in Excel file' });
        }
        
        let importedCount = 0;
        let skippedCount = 0;
        
        for (const row of data) {
            try {
                const customerCode = row['Customer Code'] || row['customer_code'] || row['CustomerCode'] || '';
                const customerName = row['Customer Name'] || row['customer_name'] || row['CustomerName'] || '';
                const area = row['Area'] || row['area'] || '';
                const route = row['Route'] || row['route'] || '';
                const address = row['Address'] || row['address'] || '';
                const distributorIdFromExcel = row['Distributor id'] || row['distributor_id'] || row['DistributorId'] || distributorId;
                
                if (!customerName || !area) {
                    skippedCount++;
                    continue;
                }
                
                const phone = row['Phone'] || row['phone'] || row['Mobile'] || row['mobile'] || '';
                
                const existingCustomer = await collections.customer.findOne({ 
                    $or: [
                        { name: customerName, distributor_id: distributorIdFromExcel },
                        { customer_id: customerCode }
                    ]
                });
                
                if (existingCustomer) {
                    skippedCount++;
                    continue;
                }
                
                const customerId = customerCode || `GK${Date.now()}${Math.floor(Math.random() * 1000)}`;
                
                const customer = {
                    name: customerName,
                    customer_id: customerId,
                    phone: phone,
                    area: area,
                    route: route || null,
                    address: address || null,
                    created_at: new Date().toISOString(),
                    updated_at: new Date().toISOString(),
                    status: 'active',
                    created_by: createdBy || 'import',
                    distributor_id: distributorIdFromExcel
                };
                
                await collections.customer.insertOne(customer);
                importedCount++;
            } catch (rowError) {
                console.error('Error importing customer row:', rowError);
                skippedCount++;
            }
        }
        
        fs.unlinkSync(req.file.path);
        
        res.json({
            success: true,
            message: `Imported ${importedCount} customers successfully. Skipped ${skippedCount} duplicates/invalid entries.`,
            importedCount: importedCount,
            skippedCount: skippedCount
        });
    } catch (error) {
        console.error('Error importing customers:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
        res.status(500).json({ error: error.message });
    }
});

// Import products from Excel
app.post('/api/import/products', excelUpload.single('file'), async (req, res) => {
    try {
        const { distributorId, createdBy } = req.body;
        
        if (!req.file) {
            return res.status(400).json({ error: 'No file uploaded' });
        }
        
        if (!distributorId) {
            return res.status(400).json({ error: 'Distributor ID is required' });
        }
        
        const workbook = XLSX.readFile(req.file.path);
        const sheetName = workbook.SheetNames[0];
        const worksheet = workbook.Sheets[sheetName];
        const data = XLSX.utils.sheet_to_json(worksheet);
        
        if (!data || data.length === 0) {
            return res.status(400).json({ error: 'No data found in Excel file' });
        }
        
        let importedCount = 0;
        let skippedCount = 0;
        
        for (const row of data) {
            try {
                const productName = row['product name'] || row['product_name'] || row['Product Name'] || row['ProductName'] || '';
                const productCode = row['Product code'] || row['product_code'] || row['ProductCode'] || row['SKU'] || row['sku'] || '';
                const mrp = parseFloat(row['MRP'] || row['mrp'] || 0);
                const price = parseFloat(row['Price'] || row['price'] || 0);
                const category = row['Category'] || row['category'] || '';
                const stockQuantity = parseInt(row['Stock Quantity'] || row['stock_quantity'] || row['Stock'] || row['stock'] || 0);
                const description = row['Description'] || row['description'] || '';
                const distributorIdFromExcel = row['Distirbutor Id'] || row['distributor_id'] || row['DistributorId'] || distributorId;
                
                if (!productName || !productCode || price <= 0) {
                    skippedCount++;
                    continue;
                }
                
                const existingProduct = await collections.product.findOne({ 
                    $or: [
                        { productName: productName, distributorId: distributorIdFromExcel },
                        { sku: productCode }
                    ]
                });
                
                if (existingProduct) {
                    skippedCount++;
                    continue;
                }
                
                const product = {
                    productName: productName,
                    sku: productCode,
                    mrp: mrp,
                    price: price,
                    category: category || 'General',
                    stock: stockQuantity,
                    stockQuantity: stockQuantity,
                    description: description || null,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString(),
                    createdBy: createdBy || 'import',
                    distributorId: distributorIdFromExcel,
                    isActive: true,
                    images: [],
                    tags: []
                };
                
                await collections.product.insertOne(product);
                importedCount++;
            } catch (rowError) {
                console.error('Error importing product row:', rowError);
                skippedCount++;
            }
        }
        
        fs.unlinkSync(req.file.path);
        
        res.json({
            success: true,
            message: `Imported ${importedCount} products successfully. Skipped ${skippedCount} duplicates/invalid entries.`,
            importedCount: importedCount,
            skippedCount: skippedCount
        });
    } catch (error) {
        console.error('Error importing products:', error);
        if (req.file && fs.existsSync(req.file.path)) {
            fs.unlinkSync(req.file.path);
        }
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
            order_data: order
        };
        
        await collections.notification.insertOne(notification);
        console.log(`Notification created for distributor ${distributorId} about order ${order.orderNumber} from salesman ${finalSalesmanName}`);
        
        return notification;
    } catch (error) {
        console.error('Error creating notification:', error);
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
        
        res.json({ success: true, message: 'Notification marked as read' });
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

// ==================== CUSTOMER APIs ====================

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
            canCollectPayment: true
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
            canCollectPayment: true
        };
        
        res.json({
            customers: customers,
            products: products,
            orders: orders,
            permissions: permissions,
            salesmanName: salesmanName
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
        
        orderData.created_by_type = orderData.created_by_type || (orderData.salesman_id ? 'salesman' : 'distributor');
        
        orderData.status = orderData.status || 'pending';
        orderData.payment_status = orderData.payment_status || 'pending';
        orderData.paidAmount = orderData.paidAmount || 0;
        orderData.dueAmount = orderData.grand_total || 0;
        
        const result = await collections.order.insertOne(orderData);
        
        console.log(`Order created: ${orderNumber} with ID: ${result.insertedId}`);
        console.log(`Order created by: ${orderData.created_by_type}, Distributor ID: ${distributorId}, Salesman ID: ${orderData.salesman_id || 'N/A'}`);
        
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
                        const quantitySold = item.quantity || item.qty || 0;
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
                    excelData.push({
                        'Order No': order.orderNumber,
                        'Order Date': new Date(order.order_date).toLocaleDateString('en-IN'),
                        'Party code': order.customerId || order.customer_id || '',
                        'Party name': order.customerName || '',
                        'Product code': item.productCode || item.sku || item.productId || '',
                        'Product name': item.productName || item.name || '',
                        'MRP': item.mrp || item.price || 0,
                        'Rate': item.rate || item.price || 0,
                        'Unit': 'PCS',
                        'SSMcode': salesmanCode,
                        'Salesman name': salesmanName,
                        'Net amount': (item.quantity || item.qty || 0) * (item.rate || item.price || 0)
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
            { wch: 30 }, { wch: 10 }, { wch: 10 }, { wch: 6 }, { wch: 12 },
            { wch: 20 }, { wch: 12 }
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

// ==================== PAYMENT APIs ====================

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

app.post('/api/orders/:orderId/payment', upload.single('paymentPhoto'), async (req, res) => {
    try {
        const { orderId } = req.params;
        const { 
            amount, 
            paymentMode, 
            reference, 
            collectedBy, 
            collectedByName,
            collectedByType,
            salesmanId,
            salesmanName,
            chequeNumber,
            chequeDate,
            bankName,
            upiType,
            transactionNumber,
            remark
        } = req.body;
        
        console.log(`Looking for order with ID: ${orderId}`);
        
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
        
        const paymentAmount = parseFloat(amount);
        const newPaidAmount = (order.paidAmount || 0) + paymentAmount;
        const newDueAmount = order.grand_total - newPaidAmount;
        
        const collectionId = generateCollectionId();
        
        let paymentModesDetails = {};
        
        if (paymentMode === 'Cheque' || paymentMode === 'cheque') {
            paymentModesDetails = {
                mode: 'Cheque',
                reference_number: chequeNumber,
                bank_name: bankName,
                cheque_date: chequeDate
            };
        } else if (paymentMode === 'UPI' || paymentMode === 'upi') {
            let photoPath = null;
            if (req.file) {
                photoPath = req.file.path;
                console.log(`UPI payment photo saved at: ${photoPath}`);
            } else if (req.body.paymentPhoto) {
                console.log(`UPI payment photo provided as string`);
            }
            
            paymentModesDetails = {
                mode: 'UPI',
                reference_number: transactionNumber,
                upi_type: upiType,
                photo_path: photoPath
            };
        } else if (paymentMode === 'Cash' || paymentMode === 'cash') {
            paymentModesDetails = {
                mode: 'Cash',
                reference_number: null,
                bank_name: null,
                cheque_date: null
            };
        } else {
            paymentModesDetails = {
                mode: paymentMode,
                reference_number: reference || null,
                bank_name: null,
                cheque_date: null
            };
        }
        
        const paymentRecord = {
            collection_id: collectionId,
            collection_date: new Date().toISOString(),
            customer_id: order.customerId,
            customer_name: order.customerName,
            amount_collected: paymentAmount,
            payment_mode: paymentMode,
            collected_by: {
                type: collectedByType || (collectedByType === 'salesman' ? 'salesman' : 'distributor'),
                id: collectedBy,
                name: collectedByName,
                time: new Date().toISOString()
            },
            salesman_details: salesmanId ? {
                id: salesmanId,
                name: salesmanName,
                time: new Date().toISOString()
            } : null,
            payment_modes_details: paymentModesDetails,
            order_details: {
                order_id: order.orderNumber,
                order_amount: order.grand_total,
                previous_paid: order.paidAmount || 0,
                previous_due: order.dueAmount || order.grand_total
            },
            remark: remark || null,
            status: newDueAmount <= 0 ? 'completed' : 'partial',
            created_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
        };
        
        const paymentResult = await collections.payment.insertOne(paymentRecord);
        console.log(`Payment recorded with ID: ${paymentResult.insertedId}, Collection ID: ${collectionId}`);
        
        const updateData = { 
            paidAmount: newPaidAmount,
            dueAmount: newDueAmount,
            payment_method: paymentMode,
            paymentReference: reference || chequeNumber || transactionNumber,
            collectedBy: collectedBy,
            paymentCollectedBySalesman: salesmanId || null,
            paymentCollectedAt: new Date().toISOString(),
            updatedAt: new Date().toISOString(),
            payment_status: newDueAmount <= 0 ? 'paid' : 'partial',
            status: newDueAmount <= 0 ? 'delivered' : order.status
        };
        
        if (paymentMode === 'Cheque' || paymentMode === 'cheque') {
            updateData.chequeNumber = chequeNumber;
            updateData.chequeDate = chequeDate;
            updateData.bankName = bankName;
        } else if (paymentMode === 'UPI' || paymentMode === 'upi') {
            updateData.upiType = upiType;
            updateData.transactionNumber = transactionNumber;
            if (req.file) {
                updateData.paymentPhoto = req.file.path;
            }
        }
        
        const result = await collections.order.updateOne(
            { _id: order._id },
            { $set: updateData }
        );
        
        console.log(`Order ${order.orderNumber} updated with payment info`);
        
        res.json({ 
            success: true, 
            message: 'Payment recorded successfully',
            payment_id: paymentResult.insertedId,
            collection_id: collectionId,
            new_due_amount: newDueAmount,
            order_updated: true
        });
    } catch (error) {
        console.error('Error recording payment:', error);
        res.status(500).json({ error: error.message });
    }
});

app.get('/api/customers/:customerId/outstanding', async (req, res) => {
    try {
        const { customerId } = req.params;
        
        const orders = await collections.order
            .find({ 
                customerId: customerId,
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
// Start server
app.listen(process.env.PORT, async () => {
    await connectToMongoDB();
    console.log(`Server running on http://localhost:${process.env.PORT}`);
    console.log(`API endpoints available at http://localhost:${process.env.PORT}/api`);
    console.log(`\nAPI Endpoints:`);
    console.log(`\nAuth:`);
    console.log(`  POST /api/login - User login`);
    console.log(`  POST /api/logout - User logout`);
    console.log(`  POST /api/register - User registration`);
    console.log(`\nImport Master Data (NEW):`);
    console.log(`  POST /api/import/customers - Import customers from Excel`);
    console.log(`  POST /api/import/products - Import products from Excel`);
    console.log(`\nDistributors:`);
    console.log(`  GET /api/distributors - Get all distributors`);
    console.log(`  GET /api/distributors/:distributorId - Get distributor by ID`);
    console.log(`\nCustomers:`);
    console.log(`  GET /api/customers/:distributorId - Get all customers`);
    console.log(`  POST /api/customers - Add new customer`);
    console.log(`  GET /api/customers/id/:id - Get single customer`);
    console.log(`  PUT /api/customers/:id - Update customer`);
    console.log(`  DELETE /api/customers/:id - Delete customer`);
    console.log(`\nProducts:`);
    console.log(`  GET /api/products/:distributorId - Get all products (includes MRP field)`);
    console.log(`  POST /api/products - Add new product (includes MRP)`);
    console.log(`  GET /api/products/id/:id - Get single product`);
    console.log(`  PUT /api/products/:id - Update product`);
    console.log(`  DELETE /api/products/:id - Delete product`);
    console.log(`  PUT /api/products/:id/stock - Update product stock (FIXED: correct calculation)`);
    console.log(`  GET /api/products/:productId/last-sale - Get last sale for product`);
    console.log(`\nSalesmen:`);
    console.log(`  GET /api/salesmen/:distributorId - Get all salesmen`);
    console.log(`  POST /api/salesmen - Add new salesman`);
    console.log(`  GET /api/salesmen/id/:id - Get single salesman`);
    console.log(`  GET /api/salesmen/by-id/:salesmanId - Get salesman by salesman_id`);
    console.log(`  PUT /api/salesmen/:id - Update salesman`);
    console.log(`  DELETE /api/salesmen/:id - Delete salesman`);
    console.log(`\nPermissions:`);
    console.log(`  GET /api/salesmen/permissions/:salesmanId - Get permissions`);
    console.log(`  PUT /api/salesmen/permissions/:salesmanId - Update permissions`);
    console.log(`\nSalesman Data:`);
    console.log(`  GET /api/salesman-data/:salesmanId - Get all data for salesman`);
    console.log(`\nOrders:`);
    console.log(`  POST /api/orders - Create order (auto-updates stock and sets distributor_id, includes MRP)`);
    console.log(`  GET /api/orders/salesman/:salesmanId - Get orders by salesman`);
    console.log(`  GET /api/orders/distributor/:distributorId - Get orders by distributor`);
    console.log(`  GET /api/orders/download/:distributorId - Download orders as Excel with MRP column`);
    console.log(`  GET /api/orders/customer/:customerId - Get orders by customer`);
    console.log(`  GET /api/orders/customer/:customerId/last - Get last order by customer`);
    console.log(`  GET /api/orders/:orderId - Get single order`);
    console.log(`  PUT /api/orders/:orderId/status - Update order status`);
    console.log(`\nPayments:`);
    console.log(`  POST /api/orders/:orderId/payment - Record payment with file upload`);
    console.log(`  GET /api/payments - Get all payments`);
    console.log(`  GET /api/payments/distributor/:distributorId - Get payments by distributor`);
    console.log(`  GET /api/payments/salesman/:salesmanId - Get payments by salesman`);
    console.log(`  GET /api/payments/order/:orderId - Get payments by order`);
    console.log(`  GET /api/customers/:customerId/outstanding - Get customer outstanding balance`);
    console.log(`  GET /api/banks - Get list of Indian banks`);
    console.log(`  GET /api/upi-types - Get list of UPI types`);
    console.log(`\nNotifications:`);
    console.log(`  GET /api/notifications/:distributorId - Get notifications for distributor`);
    console.log(`  GET /api/notifications/unread-count/:distributorId - Get unread count`);
    console.log(`  PUT /api/notifications/:notificationId/read - Mark notification as read`);
    console.log(`  PUT /api/notifications/mark-all-read/:distributorId - Mark all as read`);
    console.log(`\nAreas & Routes:`);
    console.log(`  GET /api/areas - Get major Indian cities and areas`);
    console.log(`  GET /api/sub-areas - Get real sub-areas/routes for selected area`);
    console.log(`\nPassword Change:`);
    console.log(`  POST /api/change-password - Change user password`);
    console.log(`  GET /api/users-under-distributor/:distributorId - Get users under distributor`);
    console.log(`\nAll issues fixed in this version:`);
    console.log(`  1) MRP field added to products - products now have both MRP and Rate/Price`);
    console.log(`  2) Excel download now includes MRP column for orders`);
    console.log(`  3) Stock calculation is CORRECT - subtracts sold quantity from current stock`);
    console.log(`  4) Import Master Data - Customers and Products can be imported from Excel`);
});