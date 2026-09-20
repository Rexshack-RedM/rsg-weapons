const WagonShop = {
    isOpen: false,
    store: null,
    categories: [],
    wagons: [],
    myWagons: [],
    selectedMyWagon: null,
    playerMoney: { cash: 0, gold: 0 },
    imagePath: 'nui://rsg-wagons/images/',
    resourceName: 'rsg-wagons',
    selectedCustomType: null,
    selectedCustomValue: null,
    pendingNameWagon: null,
    pendingConfirm: null,
    pendingChop: null,

    init() {
        this.bindEvents();
        this.setupNUICallbacks();
    },

    bindEvents() {
        document.getElementById('close-btn').addEventListener('click', () => this.close());
        document.getElementById('header-back').addEventListener('click', () => {
            const wrapper = document.getElementById('wagon-grid-wrapper');
            if (wrapper && !wrapper.classList.contains('hidden')) {
                wrapper.classList.add('hidden');
                document.getElementById('category-grid').classList.remove('hidden');
                this.updateFooter('Browse wagon categories to find your perfect wagon');
            } else {
                this.switchView('store');
                document.querySelectorAll('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.view === 'store'));
            }
        });

        document.getElementById('rotate-left').addEventListener('click', () => this.sendNUI('rotateWagon', { direction: 'left' }));
        document.getElementById('rotate-right').addEventListener('click', () => this.sendNUI('rotateWagon', { direction: 'right' }));

        document.getElementById('btn-back-category').addEventListener('click', () => {
            document.getElementById('wagon-grid-wrapper').classList.add('hidden');
            document.getElementById('category-grid').classList.remove('hidden');
            this.updateFooter('Browse wagon categories to find your perfect wagon');
        });

        document.getElementById('btn-back-customize').addEventListener('click', () => this.backFromCustomize());

        document.getElementById('btn-cancel-customize').addEventListener('click', () => this.backFromCustomize());

        document.getElementById('btn-save-customize').addEventListener('click', () => this.saveCustomization());

        document.getElementById('name-modal-close').addEventListener('click', () => this.closeNameModal());
        document.getElementById('name-modal-cancel').addEventListener('click', () => this.closeNameModal());
        document.getElementById('name-modal-confirm').addEventListener('click', () => this.confirmName());

        document.getElementById('confirm-modal-close').addEventListener('click', () => this.closeConfirmModal());
        document.getElementById('confirm-modal-cancel').addEventListener('click', () => this.closeConfirmModal());
        document.getElementById('confirm-modal-confirm').addEventListener('click', () => this.confirmAction());

        document.getElementById('btn-chop-cancel').addEventListener('click', () => this.close());
        document.getElementById('btn-chop-confirm').addEventListener('click', () => this.confirmChop());

        document.querySelectorAll('.nav-btn').forEach(btn => {
            btn.addEventListener('click', () => {
                document.querySelectorAll('.nav-btn').forEach(b => b.classList.remove('active'));
                btn.classList.add('active');
                this.switchView(btn.dataset.view);
            });
        });

        document.addEventListener('keydown', (e) => {
            if (e.key === 'Escape') {
                const nameModal = document.getElementById('name-modal');
                const confirmModal = document.getElementById('confirm-modal');
                if (!nameModal.classList.contains('hidden')) { this.closeNameModal(); return; }
                if (!confirmModal.classList.contains('hidden')) { this.closeConfirmModal(); return; }
                if (this.isOpen) this.close();
            }
        });

        const nameInput = document.getElementById('name-input');
        nameInput.addEventListener('keydown', (e) => {
            if (e.key === 'Enter') this.confirmName();
        });
    },

    setupNUICallbacks() {
        window.addEventListener('message', (event) => {
            const data = event.data;
            if (!data || !data.action) return;

            switch (data.action) {
                case 'openStore':
                    this.openStore(data);
                    break;
                case 'openChop':
                    this.openChop(data);
                    break;
                case 'close':
                    this.hide();
                    break;
                case 'showWagons':
                    this.showWagons(data.wagons);
                    break;
                case 'updateMoney':
                    this.updateMoney(data.cash, data.gold);
                    break;
                case 'showMyWagons':
                    this.showMyWagons(data.wagons, data.customs);
                    break;
                case 'showCustomOptions':
                    this.showCustomOptions(data.type, data.options, data.price);
                    break;
                case 'notify':
                    this.showNotification(data.type, data.title, data.message);
                    break;
                case 'success':
                    this.showSuccess(data.message);
                    break;
            }
        });
    },

    sendNUI(endpoint, data) {
        return fetch(`https://${this.resourceName}/${endpoint}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(data || {})
        }).catch(() => {});
    },

    openStore(data) {
        this.store = data.store;
        this.categories = data.categories || [];
        this.wagons = [];
        this.playerMoney = data.playerMoney || { cash: 0, gold: 0 };

        this.isOpen = true;

        const container = document.getElementById('shop-container');
        container.classList.remove('theme-bw', 'theme-color');

        document.getElementById('shop-name').textContent = 'WAGON SHOP';
        document.getElementById('shop-subtitle').textContent = 'Quality Wagons & Supplies';
        document.getElementById('nav-tabs').classList.remove('hidden');
        document.querySelectorAll('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.view === 'store'));
        this.updateMoneyDisplay();

        this.renderCategories();

        document.getElementById('category-grid').classList.remove('hidden');
        document.getElementById('wagon-grid-wrapper').classList.add('hidden');
        this.switchView('store');

        container.classList.remove('hidden');
    },

    renderCategories() {
        const grid = document.getElementById('category-grid');
        grid.innerHTML = '';

        this.categories.forEach(cat => {
            const card = document.createElement('div');
            card.className = 'category-card';
            card.innerHTML = `
                <img src="${this.imagePath}wagon.png" alt="${cat.label}">
                <div class="category-name">${cat.label}</div>
            `;
            card.addEventListener('click', () => this.selectCategory(cat));
            grid.appendChild(card);
        });
    },

    selectCategory(cat) {
        this.sendNUI('getWagonsByType', { type: cat.type, store: this.store });
        document.getElementById('category-title').textContent = cat.label;
        document.getElementById('category-grid').classList.add('hidden');
        document.getElementById('wagon-grid-wrapper').classList.remove('hidden');
    },

    showWagons(wagons) {
        this.wagons = wagons || [];
        const grid = document.getElementById('wagon-grid');
        const noItems = document.getElementById('no-wagons');
        grid.innerHTML = '';

        if (this.wagons.length === 0) {
            grid.classList.add('hidden');
            noItems.classList.remove('hidden');
            return;
        }

        grid.classList.remove('hidden');
        noItems.classList.add('hidden');

        this.wagons.forEach((w, idx) => {
            const card = document.createElement('div');
            card.className = 'wagon-card';
            if (idx === 0) card.classList.add('selected');

            const statsParts = [];
            if (w.price) statsParts.push(`$${w.price}`);
            if (w.slots) statsParts.push(`Slots: ${w.slots}`);
            if (w.maxWeight) statsParts.push(`${w.maxWeight}kg`);
            if (w.maxAnimals) statsParts.push(`Animals: ${w.maxAnimals}`);

            card.innerHTML = `
                <div class="wagon-icon">
                    <img src="${this.imagePath}wagon.png" alt="${w.name}">
                </div>
                <div class="wagon-name">${w.name}</div>
                <div class="wagon-price">$${w.price || 0}</div>
                <div class="wagon-stats">${statsParts.join(' | ')}</div>
                <button class="buy-btn" data-model="${w.model}"><i class="fa-solid fa-cart-plus"></i> BUY</button>
            `;

            card.querySelector('.buy-btn').addEventListener('click', (e) => {
                e.stopPropagation();
                this.promptBuyWagon(w);
            });

            card.addEventListener('click', () => {
                grid.querySelectorAll('.wagon-card').forEach(c => c.classList.remove('selected'));
                card.classList.add('selected');
                this.sendNUI('previewWagon', { model: w.model, store: this.store });
            });

            grid.appendChild(card);
        });

        if (this.wagons[0]) {
            this.sendNUI('previewWagon', { model: this.wagons[0].model, store: this.store });
        }
    },

    promptBuyWagon(w) {
        this.pendingNameWagon = w;
        const modal = document.getElementById('name-modal');
        document.getElementById('name-input').value = '';
        modal.classList.remove('hidden');
        setTimeout(() => document.getElementById('name-input').focus(), 100);
    },

    confirmName() {
        const input = document.getElementById('name-input');
        const name = input.value.trim();
        if (!name || name.length < 1 || name.length > 16) {
            this.showNotification('error', 'Invalid Name', 'Name must be 1-16 characters');
            return;
        }
        if (this.pendingNameWagon) {
            this.sendNUI('buyWagon', { model: this.pendingNameWagon.model, name: name, store: this.store });
            this.closeNameModal();
        }
    },

    closeNameModal() {
        document.getElementById('name-modal').classList.add('hidden');
        this.pendingNameWagon = null;
    },

    showConfirm(title, message, onConfirm) {
        this.pendingConfirm = onConfirm;
        document.getElementById('confirm-title').textContent = title;
        document.getElementById('confirm-message').textContent = message;
        document.getElementById('confirm-modal').classList.remove('hidden');
    },

    closeConfirmModal() {
        document.getElementById('confirm-modal').classList.add('hidden');
        this.pendingConfirm = null;
    },

    confirmAction() {
        if (this.pendingConfirm) {
            this.pendingConfirm();
            this.pendingConfirm = null;
        }
        this.closeConfirmModal();
    },

    openChop(data) {
        this.pendingChop = { netId: data.netId, modelName: data.modelName };
        this.isOpen = true;

        const container = document.getElementById('shop-container');
        container.classList.remove('theme-bw', 'theme-color');

        document.getElementById('shop-name').textContent = 'CHOP SHOP';
        document.getElementById('shop-subtitle').textContent = 'Scrap Wagons for Parts';
        document.getElementById('nav-tabs').classList.add('hidden');

        document.getElementById('chop-wagon-name').textContent = data.displayName || data.modelName || 'Wagon';
        document.getElementById('chop-wagon-model').textContent = data.modelName || '';

        const rewardsBox = document.getElementById('chop-rewards');
        rewardsBox.innerHTML = '';
        (data.rewards || []).forEach(r => {
            const row = document.createElement('div');
            row.className = 'customize-option-item';
            row.innerHTML = `
                <span class="opt-label">${r.label || r.item}</span>
                <span class="opt-price">${r.amount}</span>
            `;
            rewardsBox.appendChild(row);
        });

        const note = document.getElementById('chop-owned-note');
        if (data.isRegistered) {
            note.textContent = 'Registered wagon - owner only. Scrapping permanently deletes it.';
            note.classList.remove('hidden');
        } else {
            note.classList.add('hidden');
        }

        this.switchView('chop');
        this.updateFooter('Confirm to scrap this wagon for the parts above');
        container.classList.remove('hidden');
    },

    confirmChop() {
        if (!this.pendingChop) return;
        this.sendNUI('confirmChop', this.pendingChop);
        this.pendingChop = null;
        this.close();
    },

    switchView(view) {
        document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
        document.getElementById(`view-${view}`).classList.remove('hidden');

        if (view === 'mywagons') {
            this.sendNUI('getMyWagons');
            this.updateFooter('Select a wagon to view details or customize');
        } else {
            this.updateFooter('Browse wagon categories to find your perfect wagon');
        }
    },

    showMyWagons(wagons, customs) {
        this.myWagons = wagons || [];
        const container = document.getElementById('mywagons-items');
        const noItems = document.getElementById('no-mywagons');
        const detailPanel = document.getElementById('wagon-detail-panel');
        container.innerHTML = '';

        if (this.myWagons.length === 0) {
            container.classList.add('hidden');
            noItems.classList.remove('hidden');
            detailPanel.classList.add('hidden');
            return;
        }

        container.classList.remove('hidden');
        noItems.classList.add('hidden');

        this.myWagons.forEach((w, i) => {
            const custom = (customs && customs[i]) || {};
            const item = document.createElement('div');
            item.className = 'mywagon-item';
            if (i === 0) { item.classList.add('active'); this.selectMyWagon(w, custom); }

            item.innerHTML = `
                <div class="wagon-icon"><i class="fa-solid fa-horse"></i></div>
                <div class="wagon-info">
                    <div class="name">${custom.name || 'Unnamed Wagon'}</div>
                    <div class="model-name">${w}</div>
                </div>
            `;

            item.addEventListener('click', () => {
                container.querySelectorAll('.mywagon-item').forEach(c => c.classList.remove('active'));
                item.classList.add('active');
                this.selectMyWagon(w, custom);
            });

            container.appendChild(item);
        });
    },

    selectMyWagon(model, custom) {
        this.selectedMyWagon = { model, custom };
        const panel = document.getElementById('wagon-detail-panel');
        panel.classList.remove('hidden');

        document.getElementById('detail-wagon-name').textContent = custom.name || 'Unnamed Wagon';
        document.getElementById('detail-wagon-model').textContent = model;

        const actions = document.getElementById('detail-actions');
        const customizeSection = document.getElementById('customize-section');

        actions.innerHTML = '';

        const activateBtn = document.createElement('div');
        activateBtn.className = 'detail-action-btn activate';
        activateBtn.innerHTML = '<i class="fa-solid fa-play"></i> Activate Wagon <span class="pill">Call Out</span>';
        activateBtn.addEventListener('click', () => {
            this.sendNUI('activateWagon', { model: model, custom: custom });
            this.close();
        });
        actions.appendChild(activateBtn);

        customizeSection.classList.remove('hidden');
        const customizeOpts = document.getElementById('customize-options');
        customizeOpts.innerHTML = '';

        const customTypes = [
            { type: 'livery', icon: 'fa-palette', label: 'Livery' },
            { type: 'tint', icon: 'fa-paint-roller', label: 'Paint' },
            { type: 'extra', icon: 'fa-plus-circle', label: 'Extras' },
            { type: 'props', icon: 'fa-box', label: 'Props' },
            { type: 'lantern', icon: 'fa-lightbulb', label: 'Lanterns' },
        ];

        customTypes.forEach(ct => {
            const btn = document.createElement('button');
            btn.className = 'customize-btn';
            btn.innerHTML = `<i class="fa-solid ${ct.icon}"></i> ${ct.label} <span class="pill">$${this.getCustomPrice(ct.type)}</span>`;
            btn.addEventListener('click', () => {
                this.selectedCustomType = ct.type;
                this.sendNUI('getCustomOptions', { type: ct.type, model: model, custom: custom });
            });
            customizeOpts.appendChild(btn);
        });

        const sellBtn = document.createElement('div');
        sellBtn.className = 'detail-action-btn sell';
        sellBtn.innerHTML = '<i class="fa-solid fa-trash"></i> Sell Wagon <span class="pill">Permanent</span>';
        sellBtn.addEventListener('click', () => {
            this.showConfirm('Sell Wagon', `Are you sure you want to sell this wagon?`, () => {
                this.sendNUI('sellWagon', { model: model, custom: custom });
                this.close();
            });
        });
        actions.appendChild(sellBtn);

        this.sendNUI('previewMyWagon', { model: model, custom: custom });
    },

    getCustomPrice(type) {
        const prices = { livery: 15, extra: 25, tint: 38, props: 15, lantern: 15 };
        return prices[type] || 0;
    },

    showCustomOptions(type, options, price) {
        this.selectedCustomValue = null;
        document.getElementById('btn-save-customize').disabled = true;

        const container = document.getElementById('customize-items');
        container.innerHTML = '';
        document.getElementById('customize-preview-title').textContent =
            `Select ${type.charAt(0).toUpperCase() + type.slice(1)}`;

        options.forEach(opt => {
            const item = document.createElement('div');
            item.className = 'customize-option-item';

            const value = opt.value;
            const label = opt.label;
            const displayPrice = price || this.getCustomPrice(type);

            item.innerHTML = `
                <span class="opt-label">${label}</span>
                <span class="opt-price">$${displayPrice}</span>
            `;

            item.addEventListener('click', () => {
                container.querySelectorAll('.customize-option-item').forEach(c => c.classList.remove('selected'));
                item.classList.add('selected');
                this.selectedCustomValue = value;
                document.getElementById('btn-save-customize').disabled = false;
                this.sendNUI('previewCustom', { type: type, value: value });
            });

            container.appendChild(item);
        });

        document.getElementById('customize-preview').classList.remove('hidden');
        document.getElementById('customize-options').classList.add('hidden');
    },

    backFromCustomize() {
        this.selectedCustomType = null;
        this.selectedCustomValue = null;
        document.getElementById('customize-preview').classList.add('hidden');
        document.getElementById('customize-options').classList.remove('hidden');
        if (this.selectedMyWagon) {
            this.sendNUI('resetPreview', { model: this.selectedMyWagon.model, custom: this.selectedMyWagon.custom });
        }
    },

    saveCustomization() {
        if (!this.selectedCustomType || this.selectedCustomValue === null) return;
        if (!this.selectedMyWagon) return;

        this.sendNUI('saveCustomization', {
            type: this.selectedCustomType,
            value: this.selectedCustomValue,
            model: this.selectedMyWagon.model,
            custom: this.selectedMyWagon.custom
        });

        if (this.selectedMyWagon.custom) {
            this.selectedMyWagon.custom[this.selectedCustomType] = this.selectedCustomValue;
        }

        this.backFromCustomize();
    },

    updateMoneyDisplay() {
        document.getElementById('player-cash').textContent = '$' + (this.playerMoney.cash || 0).toFixed(2);
        document.getElementById('player-gold').textContent = this.playerMoney.gold || 0;
    },

    updateMoney(cash, gold) {
        this.playerMoney = { cash: cash || 0, gold: gold || 0 };
        this.updateMoneyDisplay();
    },

    updateFooter(text) {
        document.getElementById('footer-hint').textContent = text;
    },

    close() {
        this.hide();
        this.sendNUI('closeShop');
    },

    hide() {
        this.isOpen = false;
        this.selectedMyWagon = null;
        this.selectedCustomType = null;
        this.selectedCustomValue = null;
        this.pendingNameWagon = null;
        this.pendingChop = null;
        document.getElementById('nav-tabs').classList.remove('hidden');
        document.getElementById('shop-container').classList.add('hidden');
        document.getElementById('name-modal').classList.add('hidden');
        document.getElementById('confirm-modal').classList.add('hidden');
        document.getElementById('success-overlay').classList.add('hidden');
        document.getElementById('customize-preview').classList.add('hidden');
        document.getElementById('customize-options').classList.remove('hidden');
    },

    showSuccess(message) {
        document.getElementById('success-message').textContent = message || 'Action completed successfully';
        document.getElementById('success-overlay').classList.remove('hidden');
        setTimeout(() => {
            document.getElementById('success-overlay').classList.add('hidden');
        }, 2500);
    },

    showNotification(type, title, message) {
        const container = document.getElementById('notification-container');
        const icons = { success: 'fa-check-circle', error: 'fa-times-circle', info: 'fa-info-circle' };

        const notification = document.createElement('div');
        notification.className = `notification ${type}`;
        notification.innerHTML = `
            <i class="fa-solid ${icons[type] || icons.info}"></i>
            <div>
                <span class="toast-label">${title || 'Notice'}</span>
                ${message ? `<span class="toast-msg">${message}</span>` : ''}
            </div>
        `;
        container.prepend(notification);

        setTimeout(() => {
            notification.style.animation = 'toastOut 0.25s ease-in forwards';
            setTimeout(() => notification.remove(), 250);
        }, 4000);
    }
};

document.addEventListener('DOMContentLoaded', () => {
    WagonShop.init();
});
