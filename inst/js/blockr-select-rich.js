// Reusable rich select — extract to blockr.core when needed
//
// Searchable single-select with two-line dropdown items (label + description).
// Used for argument name selection where users need to see what each option does.
//
// API:
//   Blockr.SelectRich.create(container, config) -> { el, getValue, setValue, setItems, focus, isOpen, destroy }
//
// Config:
//   items: [{ value, label?, meta?, description? }]
//   selected: string (value) or null
//   placeholder: string
//   onChange: (value, item) => void

(() => {
  'use strict';

  const createSelectRich = (container, config) => {
    const id = Blockr.uid('bsr');
    const dropdownId = `${id}-lb`;

    let items = (config.items || []).slice();
    let selected = config.selected || null;
    const placeholder = config.placeholder || 'Select\u2026';
    const onChange = config.onChange || null;
    const groupColors = config.groupColors || {};
    const hasIcons = Object.keys(groupColors).length > 0;
    const iconPath = config.iconPath || '<path fill-rule="evenodd" d="M0 0h1v15h15v1H0zm14.817 3.113a.5.5 0 0 1 .07.704l-4.5 5.5a.5.5 0 0 1-.74.037L7.06 6.767l-3.656 5.027a.5.5 0 0 1-.808-.588l4-5.5a.5.5 0 0 1 .758-.06l2.609 2.61 4.15-5.073a.5.5 0 0 1 .704-.07"/>';
    const defaultColor = '#64748b';
    let _isOpen = false;
    let searchQuery = '';
    let highlightIdx = 0;
    let destroyed = false;

    // DOM
    const root = document.createElement('div');
    root.className = 'blockr-srich';
    root.setAttribute('tabindex', '0');
    root.setAttribute('role', 'combobox');
    root.setAttribute('aria-expanded', 'false');
    root.setAttribute('aria-owns', dropdownId);

    // Control area (shows selected value)
    const control = document.createElement('div');
    control.className = 'blockr-srich__control';

    const valueEl = document.createElement('span');
    valueEl.className = 'blockr-srich__value';

    const searchInput = document.createElement('input');
    searchInput.type = 'text';
    searchInput.className = 'blockr-srich__search';
    searchInput.setAttribute('autocomplete', 'off');
    searchInput.setAttribute('autocorrect', 'off');
    searchInput.setAttribute('autocapitalize', 'off');
    searchInput.setAttribute('spellcheck', 'false');
    searchInput.setAttribute('tabindex', '-1');

    const arrow = document.createElement('span');
    arrow.className = 'blockr-srich__arrow';
    arrow.innerHTML = Blockr.icons.chevron;

    control.appendChild(valueEl);
    control.appendChild(searchInput);
    control.appendChild(arrow);
    root.appendChild(control);

    // Dropdown
    const dropdown = document.createElement('div');
    dropdown.className = 'blockr-srich__dropdown';
    dropdown.id = dropdownId;
    dropdown.setAttribute('role', 'listbox');
    root.appendChild(dropdown);

    container.appendChild(root);

    // --- Color & icon helpers ---

    const hexToRgba = (hex, alpha) => {
      const r = parseInt(hex.slice(1, 3), 16);
      const g = parseInt(hex.slice(3, 5), 16);
      const b = parseInt(hex.slice(5, 7), 16);
      return `rgba(${r},${g},${b},${alpha})`;
    };

    const makeSvg = (color, size) => {
      return `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" fill="${color}" viewBox="0 0 16 16">${iconPath}</svg>`;
    };

    const getGroupColor = (group) => {
      return groupColors[group] || defaultColor;
    };

    // --- Helpers ---

    const getFiltered = () => {
      if (!searchQuery) return items;
      const q = searchQuery.toLowerCase();
      const result = [];
      for (const item of items) {
        const label = (item.label || item.value).toLowerCase();
        const desc = (item.description || '').toLowerCase();
        if (label.indexOf(q) >= 0 || desc.indexOf(q) >= 0) {
          result.push(item);
        }
      }
      // Prefix matches first
      result.sort((a, b) => {
        const al = (a.label || a.value).toLowerCase();
        const bl = (b.label || b.value).toLowerCase();
        const ap = al.indexOf(q) === 0 ? 0 : 1;
        const bp = bl.indexOf(q) === 0 ? 0 : 1;
        if (ap !== bp) return ap - bp;
        return al.localeCompare(bl);
      });
      return result;
    };

    const getSelectedItem = () => {
      if (!selected) return null;
      return items.find(i => i.value === selected) || null;
    };

    // --- Rendering ---

    const render = () => {
      valueEl.innerHTML = '';
      const item = getSelectedItem();
      if (item) {
        valueEl.classList.remove('blockr-srich__value--placeholder');
        // Compact icon (only when groupColors configured)
        if (hasIcons) {
          const color = getGroupColor(item.group || item.meta);
          const iconEl = document.createElement('span');
          iconEl.className = 'blockr-srich__value-icon';
          iconEl.style.borderColor = color;
          const itemIconPath = item.icon || iconPath;
          iconEl.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" fill="${color}" viewBox="0 0 16 16">${itemIconPath}</svg>`;
          valueEl.appendChild(iconEl);
        }
        // Primary: human label
        const primary = document.createElement('span');
        primary.className = 'blockr-srich__value-primary';
        primary.textContent = item.label || item.value;
        valueEl.appendChild(primary);
        // Secondary: code name if different
        if (item.value && item.value !== item.label) {
          const secondary = document.createElement('span');
          secondary.className = 'blockr-srich__value-secondary';
          secondary.textContent = item.value;
          valueEl.appendChild(secondary);
        }
      } else {
        valueEl.textContent = placeholder;
        valueEl.classList.add('blockr-srich__value--placeholder');
      }
    };

    const renderDropdown = () => {
      dropdown.innerHTML = '';
      const filtered = getFiltered();
      if (filtered.length === 0) {
        const empty = document.createElement('div');
        empty.className = 'blockr-srich__empty';
        empty.textContent = 'No matches';
        dropdown.appendChild(empty);
        return;
      }

      if (highlightIdx >= filtered.length) highlightIdx = filtered.length - 1;
      if (highlightIdx < 0) highlightIdx = 0;

      let currentGroup = null;
      for (let i = 0; i < filtered.length; i++) {
        const item = filtered[i];

        // Group header when group changes (only when not searching)
        if (item.group && item.group !== currentGroup && !searchQuery) {
          currentGroup = item.group;
          const header = document.createElement('div');
          header.className = 'blockr-srich__group-header';
          header.textContent = currentGroup;
          dropdown.appendChild(header);
        }

        const opt = document.createElement('div');
        opt.className = 'blockr-srich__option';
        if (i === highlightIdx) opt.className += ' blockr-srich__option--highlighted';
        if (item.value === selected) opt.className += ' blockr-srich__option--selected';
        opt.setAttribute('role', 'option');
        opt.setAttribute('data-value', item.value);

        // Icon square (only when groupColors configured)
        if (hasIcons) {
          const color = getGroupColor(item.group || item.meta);
          const iconEl = document.createElement('div');
          iconEl.className = 'blockr-srich__option-icon';
          iconEl.style.borderColor = color;
          const itemIconPath = item.icon || iconPath;
          iconEl.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" fill="${color}" viewBox="0 0 16 16">${itemIconPath}</svg>`;
          opt.appendChild(iconEl);
        }

        // Content: header + description
        const content = document.createElement('div');
        content.className = 'blockr-srich__option-content';

        const header = document.createElement('div');
        header.className = 'blockr-srich__option-header';

        const label = document.createElement('span');
        label.className = 'blockr-srich__option-label';
        label.textContent = item.label || item.value;
        header.appendChild(label);

        // Show actual value in mono when different from label
        if (item.value && item.label && item.value !== item.label) {
          const code = document.createElement('span');
          code.className = 'blockr-srich__option-code';
          code.textContent = item.value;
          header.appendChild(code);
        }

        if (item.meta) {
          const meta = document.createElement('span');
          meta.className = 'blockr-srich__option-meta';
          meta.textContent = item.meta;
          header.appendChild(meta);
        }

        content.appendChild(header);

        if (item.description) {
          const desc = document.createElement('div');
          desc.className = 'blockr-srich__option-desc';
          desc.textContent = item.description;
          content.appendChild(desc);
        }

        opt.appendChild(content);
        dropdown.appendChild(opt);
      }

      scrollHighlightIntoView();
    };

    const scrollHighlightIntoView = () => {
      dropdown.querySelector('.blockr-srich__option--highlighted')
        ?.scrollIntoView({ block: 'nearest' });
    };

    // --- Open / close ---

    const open = () => {
      if (_isOpen || destroyed) return;
      _isOpen = true;
      searchQuery = '';
      searchInput.value = '';
      highlightIdx = 0;

      // Position above if no room below
      const rect = root.getBoundingClientRect();
      const spaceBelow = window.innerHeight - rect.bottom - 8;
      const openAbove = spaceBelow < 280 && rect.top > 280;

      root.classList.add('blockr-srich--open');
      root.classList.toggle('blockr-srich--above', openAbove);
      root.setAttribute('aria-expanded', 'true');

      valueEl.style.display = 'none';
      searchInput.style.width = '';
      searchInput.setAttribute('placeholder', selected
        ? (getSelectedItem()?.label || selected)
        : placeholder);

      renderDropdown();
      searchInput.focus();
    };

    const close = () => {
      if (!_isOpen) return;
      _isOpen = false;
      searchQuery = '';
      searchInput.value = '';

      root.classList.remove('blockr-srich--open', 'blockr-srich--above');
      root.setAttribute('aria-expanded', 'false');

      valueEl.style.display = '';
      searchInput.style.width = '';
      searchInput.setAttribute('placeholder', '');

      dropdown.innerHTML = '';
    };

    // --- Selection ---

    const selectItem = (value) => {
      const changed = selected !== value;
      selected = value;
      close();
      render();
      if (changed && onChange) {
        onChange(value, getSelectedItem());
      }
    };

    // --- Events ---

    const onControlClick = (e) => {
      if (e.target.closest('.blockr-srich__arrow') || !_isOpen) {
        _isOpen ? close() : open();
      }
    };

    const onSearchInput = () => {
      searchQuery = searchInput.value;
      highlightIdx = 0;
      if (!_isOpen) open();
      else renderDropdown();
    };

    const onSearchKeydown = (e) => {
      const filtered = getFiltered();
      switch (e.key) {
        case 'ArrowDown':
          e.preventDefault();
          e.stopPropagation();
          if (!_isOpen) { open(); return; }
          highlightIdx = (highlightIdx + 1) % (filtered.length || 1);
          renderDropdown();
          break;
        case 'ArrowUp':
          e.preventDefault();
          e.stopPropagation();
          if (!_isOpen) { open(); return; }
          highlightIdx = (highlightIdx - 1 + (filtered.length || 1)) % (filtered.length || 1);
          renderDropdown();
          break;
        case 'Enter':
          e.preventDefault();
          if (!_isOpen) { open(); return; }
          if (highlightIdx >= 0 && highlightIdx < filtered.length) {
            selectItem(filtered[highlightIdx].value);
          }
          break;
        case 'Escape':
          e.preventDefault();
          close();
          break;
        case 'Tab':
          close();
          break;
      }
    };

    const onDropdownClick = (e) => {
      const opt = e.target.closest('.blockr-srich__option');
      if (opt) {
        const val = opt.getAttribute('data-value');
        if (val != null) selectItem(val);
      }
    };

    const onDocumentClick = (e) => {
      if (!root.contains(e.target)) close();
    };

    const onRootKeydown = (e) => {
      if (e.target === root && !_isOpen) {
        if (e.key === 'Enter' || e.key === ' ' || e.key === 'ArrowDown' || e.key === 'ArrowUp') {
          e.preventDefault();
          open();
        }
      }
    };

    // --- Bind ---

    control.addEventListener('click', onControlClick);
    dropdown.addEventListener('mousedown', (e) => e.preventDefault());
    dropdown.addEventListener('click', onDropdownClick);
    searchInput.addEventListener('input', onSearchInput);
    searchInput.addEventListener('keydown', onSearchKeydown);
    document.addEventListener('click', onDocumentClick, true);
    root.addEventListener('keydown', onRootKeydown);

    render();

    // --- Public API ---

    return {
      el: root,

      getValue() { return selected || ''; },

      setValue(val) {
        selected = val || null;
        render();
      },

      setItems(newItems) {
        items = (newItems || []).slice();
        render();
        if (_isOpen) renderDropdown();
      },

      focus() {
        if (!destroyed) open();
      },

      isOpen() { return _isOpen; },

      destroy() {
        if (destroyed) return;
        destroyed = true;
        close();
        control.removeEventListener('click', onControlClick);
        dropdown.removeEventListener('click', onDropdownClick);
        searchInput.removeEventListener('input', onSearchInput);
        searchInput.removeEventListener('keydown', onSearchKeydown);
        document.removeEventListener('click', onDocumentClick, true);
        root.removeEventListener('keydown', onRootKeydown);
        Blockr.removeNode(root);
      }
    };
  };

  Blockr.SelectRich = {
    create: (container, config) => createSelectRich(container, config)
  };
})();
