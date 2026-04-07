/**
 * AdmiralBlock — universal admiral derive_* block.
 *
 * Function selector (grouped rich select) + dynamic argument form.
 * Required args always visible, optional args in gear popover.
 *
 * Depends on: blockr-core.js, blockr-select-rich.js, blockr-select.js
 */
(() => {
  'use strict';

  class AdmiralBlock {
    constructor(el) {
      this.el = el;
      this.catalog = {};
      this.columnNames = [];
      this.columnNamesAdd = [];
      this.selectedFn = null;
      this._callback = null;
      this._submitted = false;
      this._debounceTimer = null;
      this._argInputs = {};
      this._popoverOpen = false;
      this._buildDOM();
    }

    _autoSubmit() {
      clearTimeout(this._debounceTimer);
      this._debounceTimer = setTimeout(() => this._submit(), 300);
    }

    _submit() {
      this._submitted = true;
      if (this._callback) this._callback(true);
    }

    // --- DOM ---

    _buildDOM() {
      this.card = document.createElement('div');
      this.card.className = 'admiral-card';
      this.el.appendChild(this.card);

      // Function selector (full width)
      const fnWrap = document.createElement('div');
      fnWrap.className = 'admiral-fn-wrap';

      this._fnSelect = Blockr.SelectRich.create(fnWrap, {
        items: [],
        selected: null,
        placeholder: 'Select function\u2026',
        groupColors: {
          'Simple Derivations': '#10b981',
          'Dates & Times': '#3b82f6',
          'Duration': '#8b5cf6',
          'Flags': '#f59e0b',
          'Baseline': '#ef4444',
          'Merge & Lookup': '#06b6d4'
        },
        onChange: (value) => {
          this.selectedFn = value;
          this._rebuildForm();
          this._submit();
        }
      });

      this.card.appendChild(fnWrap);

      // Required args area
      this.requiredEl = document.createElement('div');
      this.requiredEl.className = 'admiral-required-args';
      this.card.appendChild(this.requiredEl);

      // Gear button (below required args, right-aligned)
      const gearHeader = document.createElement('div');
      gearHeader.className = 'blockr-gear-header admiral-gear-below';
      this.gearBtn = document.createElement('button');
      this.gearBtn.type = 'button';
      this.gearBtn.className = 'blockr-gear-btn';
      this.gearBtn.innerHTML = Blockr.icons.gear;
      this.gearBtn.title = 'Optional arguments';
      this.gearBtn.style.display = 'none';
      this.gearBtn.addEventListener('click', (e) => {
        e.stopPropagation();
        this._togglePopover();
      });
      gearHeader.appendChild(this.gearBtn);
      this.card.appendChild(gearHeader);

      // Popover for optional args
      this.popoverEl = document.createElement('div');
      this.popoverEl.className = 'admiral-popover';
      this.popoverEl.style.display = 'none';
      this.card.appendChild(this.popoverEl);

      // Close popover on outside click
      document.addEventListener('click', (e) => {
        if (this._popoverOpen && this.popoverEl &&
            !this.popoverEl.contains(e.target) &&
            !this.gearBtn.contains(e.target)) {
          this._closePopover();
        }
      });
    }

    _togglePopover() {
      this._popoverOpen ? this._closePopover() : this._openPopover();
    }

    _openPopover() {
      this._popoverOpen = true;
      this.popoverEl.style.display = '';
      this.gearBtn.classList.add('blockr-gear-active');
    }

    _closePopover() {
      this._popoverOpen = false;
      this.popoverEl.style.display = 'none';
      this.gearBtn.classList.remove('blockr-gear-active');
    }

    // --- Form generation ---

    _rebuildForm() {
      // Clear everything
      this.requiredEl.innerHTML = '';
      this.popoverEl.innerHTML = '';
      this._argInputs = {};
      this._closePopover();

      const fnDef = this.catalog[this.selectedFn];
      if (!fnDef || !fnDef.args) {
        this.gearBtn.style.display = 'none';
        return;
      }

      const args = fnDef.args;
      const argNames = Object.keys(args);
      let hasOptional = false;

      for (const nm of argNames) {
        const argDef = args[nm];
        const container = argDef.required ? this.requiredEl : this.popoverEl;
        if (!argDef.required) hasOptional = true;
        this._buildArgRow(container, nm, argDef);
      }

      this.gearBtn.style.display = hasOptional ? '' : 'none';
    }

    _buildArgRow(container, argName, argDef) {
      const row = document.createElement('div');
      row.className = 'admiral-arg-row';

      const labelWrap = document.createElement('div');
      labelWrap.className = 'admiral-arg-label';
      if (argDef.description) labelWrap.title = argDef.description;

      const humanLabel = document.createElement('span');
      humanLabel.className = 'admiral-arg-label-human';
      humanLabel.textContent = argDef.label || argName;
      labelWrap.appendChild(humanLabel);

      const codeLabel = document.createElement('span');
      codeLabel.className = 'admiral-arg-label-code';
      codeLabel.textContent = argName;
      labelWrap.appendChild(codeLabel);

      row.appendChild(labelWrap);

      const inputWrap = document.createElement('div');
      inputWrap.className = 'admiral-arg-input';
      row.appendChild(inputWrap);

      const input = this._buildInput(inputWrap, argName, argDef);
      this._argInputs[argName] = input;

      container.appendChild(row);
    }

    _buildInput(container, argName, argDef) {
      const defaultVal = argDef.default;

      switch (argDef.type) {
        case 'enum':
          return this._buildEnumInput(container, argDef, defaultVal);
        case 'column':
          return this._buildColumnInput(container, argDef, defaultVal);
        case 'column-list':
          return this._buildColumnListInput(container, argDef, defaultVal);
        case 'boolean':
          return this._buildBooleanInput(container, argDef, defaultVal);
        case 'numeric':
          return this._buildNumericInput(container, argDef, defaultVal);
        case 'expr':
          return this._buildExprInput(container, argDef, defaultVal);
        case 'text':
        default:
          return this._buildTextInput(container, argDef, defaultVal);
      }
    }

    _buildEnumInput(container, argDef, defaultVal) {
      const items = (argDef.values || []).map(v =>
        typeof v === 'object' ? v : { value: v, label: v }
      );
      const sel = Blockr.SelectRich.create(container, {
        items,
        selected: defaultVal || (items.length > 0 ? items[0].value : null),
        placeholder: 'Select\u2026',
        onChange: () => this._autoSubmit()
      });
      return {
        type: 'enum',
        component: sel,
        getValue: () => sel.getValue() || null,
        destroy: () => sel.destroy()
      };
    }

    _buildColumnInput(container, argDef, defaultVal) {
      const sel = Blockr.Select.single(container, {
        options: this.columnNames,
        selected: defaultVal || '',
        placeholder: argDef.description || 'Select column\u2026',
        onChange: () => this._autoSubmit()
      });
      sel.el.classList.add('blockr-select--bordered');
      return {
        type: 'column',
        component: sel,
        getValue: () => sel.getValue() || null,
        updateColumns: (cols) => sel.setOptions(cols),
        destroy: () => sel.destroy()
      };
    }

    _buildColumnListInput(container, argDef, defaultVal) {
      const sel = Blockr.Select.multi(container, {
        options: this.columnNames,
        selected: defaultVal || [],
        placeholder: argDef.description || 'Select columns\u2026',
        reorderable: true,
        onChange: () => this._autoSubmit()
      });
      sel.el.classList.add('blockr-select--bordered');
      return {
        type: 'column-list',
        component: sel,
        getValue: () => {
          const v = sel.getValue();
          return (v && v.length > 0) ? v : null;
        },
        updateColumns: (cols) => sel.setOptions(cols),
        destroy: () => sel.destroy()
      };
    }

    _buildBooleanInput(container, argDef, defaultVal) {
      const wrap = document.createElement('label');
      wrap.className = 'admiral-checkbox-wrap';
      const cb = document.createElement('input');
      cb.type = 'checkbox';
      cb.checked = defaultVal === true;
      cb.addEventListener('change', () => this._autoSubmit());
      wrap.appendChild(cb);
      const text = document.createElement('span');
      text.textContent = argDef.description || '';
      text.className = 'admiral-checkbox-text';
      wrap.appendChild(text);
      container.appendChild(wrap);
      return {
        type: 'boolean',
        el: cb,
        getValue: () => cb.checked,
        destroy: () => {}
      };
    }

    _buildNumericInput(container, argDef, defaultVal) {
      const input = document.createElement('input');
      input.type = 'number';
      input.className = 'blockr-num-input';
      input.step = 'any';
      if (defaultVal != null) input.value = defaultVal;
      input.placeholder = argDef.description || 'number';
      input.addEventListener('input', () => this._autoSubmit());
      container.appendChild(input);
      return {
        type: 'numeric',
        el: input,
        getValue: () => input.value === '' ? null : parseFloat(input.value),
        destroy: () => {}
      };
    }

    _buildTextInput(container, argDef, defaultVal) {
      const input = document.createElement('input');
      input.type = 'text';
      input.className = 'admiral-text-input';
      if (defaultVal != null) input.value = defaultVal;
      input.placeholder = argDef.description || 'value';
      input.addEventListener('input', () => this._autoSubmit());
      container.appendChild(input);
      return {
        type: 'text',
        el: input,
        getValue: () => input.value || null,
        destroy: () => {}
      };
    }

    _buildExprInput(container, argDef, defaultVal) {
      const input = document.createElement('input');
      input.type = 'text';
      input.className = 'admiral-expr-input';
      if (defaultVal != null) input.value = defaultVal;
      input.placeholder = argDef.description || 'R expression';
      input.addEventListener('input', () => this._autoSubmit());
      container.appendChild(input);
      return {
        type: 'expr',
        el: input,
        getValue: () => input.value || null,
        destroy: () => {}
      };
    }

    // --- State ---

    _compose() {
      if (!this.selectedFn) return null;
      const fnDef = this.catalog[this.selectedFn];
      const args = {};

      for (const [nm, input] of Object.entries(this._argInputs)) {
        const val = input.getValue();
        if (val == null) continue;
        // Skip if matches default
        const argDef = fnDef?.args?.[nm];
        if (argDef && argDef.default != null && val === argDef.default) continue;
        // Skip empty arrays
        if (Array.isArray(val) && val.length === 0) continue;
        args[nm] = val;
      }

      return { fn: this.selectedFn, args };
    }

    getValue() {
      return this._submitted ? this._compose() : null;
    }

    setState(state) {
      if (!state) return;
      if (state.fn && state.fn !== this.selectedFn) {
        this.selectedFn = state.fn;
        this._fnSelect.setValue(state.fn);
        this._rebuildForm();
      }
      // Set argument values
      if (state.args) {
        for (const [nm, val] of Object.entries(state.args)) {
          const input = this._argInputs[nm];
          if (!input) continue;
          switch (input.type) {
            case 'enum':
              input.component.setValue(val);
              break;
            case 'column':
              input.component.setOptions(this.columnNames, typeof val === 'string' ? val : null);
              break;
            case 'column-list':
              input.component.setOptions(this.columnNames, Array.isArray(val) ? val : []);
              break;
            case 'boolean':
              input.el.checked = val === true;
              break;
            case 'numeric':
              input.el.value = val != null ? val : '';
              break;
            case 'text':
            case 'expr':
              input.el.value = val || '';
              break;
          }
        }
      }
    }

    setCatalog(cat) {
      this.catalog = cat || {};
      // Build function selector items: human label primary, fn name secondary
      const items = Object.entries(this.catalog).map(([fn, def]) => ({
        value: fn,
        label: def.label || fn,
        meta: def.group || null,
        group: def.group || null,
        description: fn + (def.description ? ' — ' + def.description : ''),
        icon: def.icon || null
      }));
      this._fnSelect.setItems(items);
    }

    updateColumns(cols) {
      this.columnNames = cols || [];
      for (const input of Object.values(this._argInputs)) {
        if (input.updateColumns) input.updateColumns(this.columnNames);
      }
    }

    updateColumnsAdd(cols) {
      this.columnNamesAdd = cols || [];
    }
  }

  // --- Shiny Input Binding ---

  const binding = new Shiny.InputBinding();
  Object.assign(binding, {
    find: (scope) => $(scope).find('.admiral-block-container'),
    getId: (el) => el.id || null,
    getValue: (el) => el._block ? el._block.getValue() : null,
    setValue: (el, value) => { if (el._block) el._block.setState(value); },
    subscribe: (el, callback) => {
      if (el._block) el._block._callback = () => callback(true);
    },
    unsubscribe: (el) => {
      if (el._block) el._block._callback = null;
    },
    initialize: (el) => {
      el._block = new AdmiralBlock(el);
      if (el._pendingCatalog) {
        el._block.setCatalog(el._pendingCatalog);
        delete el._pendingCatalog;
      }
      if (el._pendingState) {
        el._block.setState(el._pendingState);
        delete el._pendingState;
      }
      if (el._pendingColumns) {
        el._block.updateColumns(el._pendingColumns);
        delete el._pendingColumns;
      }
    }
  });
  Shiny.inputBindings.register(binding, 'blockr.admiral');

  // --- Message handlers ---

  Shiny.addCustomMessageHandler('admiral-catalog', (msg) => {
    const el = document.getElementById(msg.id);
    if (el && el._block) el._block.setCatalog(msg.catalog);
    else if (el) el._pendingCatalog = msg.catalog;
  });

  Shiny.addCustomMessageHandler('admiral-block-update', (msg) => {
    const el = document.getElementById(msg.id);
    if (el && el._block) el._block.setState(msg.state);
    else if (el) el._pendingState = msg.state;
  });

  Shiny.addCustomMessageHandler('admiral-columns', (msg) => {
    const el = document.getElementById(msg.id);
    if (el && el._block) el._block.updateColumns(msg.columns);
    else if (el) el._pendingColumns = msg.columns;
  });

  Shiny.addCustomMessageHandler('admiral-columns-add', (msg) => {
    const el = document.getElementById(msg.id);
    if (el && el._block) el._block.updateColumnsAdd(msg.columns);
  });
})();
