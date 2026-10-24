function escapedSearchRegex(search) {
    return new RegExp(String(search || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
}

function customerCompanyFilter(company) {
    if (company === '__unmapped__') {
        return {
            $or: [
                { sysCompCode: { $in: ['', null] }, companyCode: { $in: ['', null] }, companies: { $in: [[], null] } }
            ]
        };
    }
    return {
        $or: [
            { sysCompCode: company }, { sys_comp_code: company },
            { companyCode: company }, { company_code: company },
            { 'companies.sysCompCode': company }, { 'companies.companyCode': company }
        ]
    };
}

function productCompanyFilter(company) {
    if (company === '__unmapped__') {
        return {
            $or: [
                { sysCompCode: { $in: ['', null] } },
                { sys_comp_code: { $in: ['', null] } },
                { companyCode: { $in: ['', null] } },
                { company_code: { $in: ['', null] } }
            ]
        };
    }
    return {
        $or: [
            { sysCompCode: company },
            { sysCompCode: { $in: ['', null] }, sys_comp_code: company },
            { sysCompCode: { $in: ['', null] }, sys_comp_code: { $in: ['', null] }, companyCode: company },
            { sysCompCode: { $in: ['', null] }, sys_comp_code: { $in: ['', null] }, companyCode: { $in: ['', null] }, company_code: company }
        ]
    };
}

function buildSalesmanCustomerBrowseQuery({
    distributorId,
    company = '',
    route = '',
    search = '',
    status = 'all',
    createdAfter = ''
}) {
    const query = { distributor_id: distributorId };
    const filters = [];

    if (company) filters.push(customerCompanyFilter(company));
    if (route) {
        filters.push({
            $or: [
                { route },
                { route: { $in: ['', null] }, area: route }
            ]
        });
    }
    if (search) {
        const regex = escapedSearchRegex(search);
        filters.push({
            $or: [
                { name: regex },
                { customer_id: regex },
                { phone: regex },
                { mobile: regex },
                { area: regex }
            ]
        });
    }
    if (status === 'active') {
        filters.push({ $or: [{ status: /^active$/i }, { status: { $in: [null] } }] });
    } else if (status === 'inactive') {
        filters.push({ status: { $exists: true, $ne: null, $not: /^active$/i } });
    } else if (status === 'new' && createdAfter) {
        const cutoff = new Date(createdAfter);
        filters.push({
            $or: [
                { created_at: { $gte: cutoff } },
                { created_at: { $gte: cutoff.toISOString() } },
                { created_at: { $in: [null] } }
            ]
        });
    }

    if (filters.length) query.$and = filters;
    return query;
}

function buildSalesmanProductBrowseQuery({
    distributorId,
    company = '',
    search = '',
    stock = 'all'
}) {
    const query = { distributorId, isActive: true };
    const filters = [];

    if (company) filters.push(productCompanyFilter(company));
    if (search) {
        const regex = escapedSearchRegex(search);
        filters.push({
            $or: [
                { productName: regex },
                { name: regex },
                { sku: regex },
                { category: regex }
            ]
        });
    }

    const stockField = (range) => [
        { stock: range },
        { stock: { $in: [null] }, stockQuantity: range }
    ];
    if (stock === 'in') {
        filters.push({ $or: stockField({ $gt: 10 }) });
    } else if (stock === 'low') {
        filters.push({ $or: stockField({ $gt: 0, $lte: 10 }) });
    } else if (stock === 'out') {
        filters.push({
            $or: [
                ...stockField({ $lte: 0 }),
                { stock: { $in: [null] }, stockQuantity: { $in: [null] } }
            ]
        });
    }

    if (filters.length) query.$and = filters;
    return query;
}

module.exports = {
    buildSalesmanCustomerBrowseQuery,
    buildSalesmanProductBrowseQuery
};
