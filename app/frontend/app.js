// ─── Config ─────────────────────────────────────────────────────────
const API = window.location.hostname === 'localhost' ? 'http://localhost:3000/api' : '/api';
let token = localStorage.getItem('token');
let currentUser = JSON.parse(localStorage.getItem('user') || 'null');
let accounts = [];

// ─── Demo Mode (no backend needed) ─────────────────────────────────
const DEMO = true; // Set false when backend is running
const demoUser = { id: '1', name: 'Sid', email: 'sid@example.com' };
const demoAccounts = [
    { id: 'a1', account_number: 'ACC-10001001', account_type: 'savings', balance: 15420.50, currency: 'USD', status: 'active' },
    { id: 'a2', account_number: 'ACC-10001002', account_type: 'checking', balance: 3280.75, currency: 'USD', status: 'active' },
];
let demoTransactions = [
    { id: 't1', from_acc_num: 'ACC-10001001', to_acc_num: 'ACC-10001002', amount: 500, type: 'transfer', description: 'Monthly savings', created_at: new Date(Date.now() - 86400000).toISOString() },
    { id: 't2', from_acc_num: null, to_acc_num: 'ACC-10001001', amount: 3200, type: 'deposit', description: 'Salary deposit', created_at: new Date(Date.now() - 172800000).toISOString() },
    { id: 't3', from_acc_num: 'ACC-10001002', to_acc_num: null, amount: 85.50, type: 'withdrawal', description: 'Grocery store', created_at: new Date(Date.now() - 259200000).toISOString() },
    { id: 't4', from_acc_num: 'ACC-10001001', to_acc_num: 'ACC-99990001', amount: 1200, type: 'transfer', description: 'Rent payment', created_at: new Date(Date.now() - 432000000).toISOString() },
];

// ─── API Helper ─────────────────────────────────────────────────────
async function api(path, opts = {}) {
    if (DEMO) return demoApi(path, opts);
    const res = await fetch(`${API}${path}`, {
        ...opts,
        headers: { 'Content-Type': 'application/json', ...(token ? { Authorization: `Bearer ${token}` } : {}), ...opts.headers },
        body: opts.body ? JSON.stringify(opts.body) : undefined,
    });
    const data = await res.json();
    if (!res.ok) throw new Error(data.error || 'Request failed');
    return data;
}

function demoApi(path, opts) {
    return new Promise((resolve) => {
        setTimeout(() => {
            if (path === '/auth/login') resolve({ token: 'demo-token', user: demoUser });
            else if (path === '/auth/register') resolve({ user: { ...demoUser, name: opts.body?.full_name || 'New User' } });
            else if (path === '/accounts') resolve(demoAccounts);
            else if (path === '/transactions') resolve(demoTransactions);
            else if (path === '/transactions/transfer') {
                const tx = { id: 't' + Date.now(), from_acc_num: demoAccounts.find(a => a.id === opts.body.from_account)?.account_number, to_acc_num: opts.body.to_account, amount: opts.body.amount, type: 'transfer', description: opts.body.description || 'Transfer', created_at: new Date().toISOString() };
                demoTransactions.unshift(tx);
                const from = demoAccounts.find(a => a.id === opts.body.from_account);
                if (from) from.balance -= opts.body.amount;
                resolve(tx);
            }
            else resolve({});
        }, 300);
    });
}

// ─── Screen Management ──────────────────────────────────────────────
function showScreen(id) {
    document.querySelectorAll('.screen').forEach(s => s.classList.remove('active'));
    document.getElementById(id).classList.add('active');
}

function switchTab(name) {
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
    document.querySelectorAll('.nav-links li').forEach(l => l.classList.remove('active'));
    document.getElementById('tab-' + name).classList.add('active');
    event.currentTarget.classList.add('active');
    if (name === 'accounts') loadAccounts();
    if (name === 'transactions') loadTransactions();
    if (name === 'transfer') populateTransferDropdown();
}

function toast(msg, type = 'success') {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = `toast ${type} show`;
    setTimeout(() => t.classList.remove('show'), 3000);
}

// ─── Auth ───────────────────────────────────────────────────────────
document.getElementById('loginForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
        const data = await api('/auth/login', { method: 'POST', body: { email: document.getElementById('loginEmail').value, password: document.getElementById('loginPassword').value } });
        token = data.token;
        currentUser = data.user;
        localStorage.setItem('token', token);
        localStorage.setItem('user', JSON.stringify(currentUser));
        enterDashboard();
    } catch (err) { toast(err.message, 'error'); }
});

document.getElementById('registerForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
        await api('/auth/register', { method: 'POST', body: { full_name: document.getElementById('regName').value, email: document.getElementById('regEmail').value, phone: document.getElementById('regPhone').value, password: document.getElementById('regPassword').value } });
        toast('Account created! Please sign in.');
        showScreen('loginScreen');
    } catch (err) { toast(err.message, 'error'); }
});

function logout() {
    token = null; currentUser = null;
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    showScreen('loginScreen');
}

// ─── Dashboard ──────────────────────────────────────────────────────
async function enterDashboard() {
    showScreen('dashboard');
    document.getElementById('userName').textContent = currentUser.name;
    document.getElementById('userAvatar').textContent = currentUser.name.split(' ').map(n => n[0]).join('');
    const hr = new Date().getHours();
    document.getElementById('greeting').textContent = hr < 12 ? 'Good morning ☀️' : hr < 17 ? 'Good afternoon 🌤️' : 'Good evening 🌙';
    await loadOverview();
}

async function loadOverview() {
    try {
        accounts = await api('/accounts');
        const txs = await api('/transactions');
        const total = accounts.reduce((s, a) => s + parseFloat(a.balance), 0);
        const savings = accounts.find(a => a.account_type === 'savings');
        const checking = accounts.find(a => a.account_type === 'checking');
        document.getElementById('totalBalance').textContent = formatCurrency(total);
        document.getElementById('savingsBalance').textContent = formatCurrency(savings?.balance || 0);
        document.getElementById('checkingBalance').textContent = formatCurrency(checking?.balance || 0);
        document.getElementById('txCount').textContent = txs.length;
        renderTransactions(txs.slice(0, 5), 'recentTransactions');
    } catch (err) { toast(err.message, 'error'); }
}

async function loadAccounts() {
    accounts = await api('/accounts');
    const el = document.getElementById('accountsList');
    el.innerHTML = accounts.map(a => `
        <div class="account-card">
            <div class="account-type">${a.account_type}</div>
            <div class="account-number">${a.account_number}</div>
            <div class="account-balance">${formatCurrency(a.balance)}</div>
            <span class="account-status ${a.status}">${a.status}</span>
        </div>
    `).join('');
}

async function loadTransactions() {
    const txs = await api('/transactions');
    renderTransactions(txs, 'allTransactions');
}

function renderTransactions(txs, containerId) {
    const el = document.getElementById(containerId);
    if (!txs.length) { el.innerHTML = '<p class="empty-state">No transactions yet</p>'; return; }
    el.innerHTML = txs.map(t => {
        const isDebit = t.from_acc_num && accounts.some(a => a.account_number === t.from_acc_num);
        return `<div class="tx-item">
            <div class="tx-info">
                <span class="tx-desc">${t.description || t.type}</span>
                <span class="tx-date">${new Date(t.created_at).toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' })}</span>
                <span class="tx-acc">${isDebit ? '→ ' + (t.to_acc_num || 'External') : '← ' + (t.from_acc_num || 'External')}</span>
            </div>
            <span class="tx-amount ${isDebit ? 'debit' : 'credit'}">${isDebit ? '-' : '+'}${formatCurrency(t.amount)}</span>
        </div>`;
    }).join('');
}

function populateTransferDropdown() {
    const sel = document.getElementById('fromAccount');
    sel.innerHTML = accounts.map(a => `<option value="${a.id}">${a.account_type} (${a.account_number}) - ${formatCurrency(a.balance)}</option>`).join('');
}

document.getElementById('transferForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    try {
        await api('/transactions/transfer', { method: 'POST', body: {
            from_account: document.getElementById('fromAccount').value,
            to_account: document.getElementById('toAccount').value,
            amount: parseFloat(document.getElementById('txAmount').value),
            description: document.getElementById('txDesc').value
        }});
        toast('Transfer successful! 🎉');
        document.getElementById('transferForm').reset();
        await loadOverview();
    } catch (err) { toast(err.message, 'error'); }
});

// ─── Helpers ────────────────────────────────────────────────────────
function formatCurrency(n) { return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(n); }

// ─── Auto-login if token exists ─────────────────────────────────────
if (token && currentUser) { enterDashboard(); }
