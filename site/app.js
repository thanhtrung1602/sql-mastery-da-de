/**
 * SQL MASTERY (DA & DE) - SINGLE PAGE APPLICATION LOGIC
 * Offline SQL Execution Engine, Interactive Practice, Search & Progress Tracking
 */

(function () {
  'use strict';

  // --- 1. STATE & STORAGE ---
  const state = {
    currentLessonId: null,
    currentTrack: 'All',
    currentTab: 'auto', // 'lesson', 'practice', 'raw', 'playground', 'erd', 'cheatsheet'
    theme: localStorage.getItem('sql_theme') || 'dark',
    fontScale: parseFloat(localStorage.getItem('sql_font_scale')) || 1.0,
    completedLessons: new Set(JSON.parse(localStorage.getItem('sql_completed_lessons') || '[]')),
    completedExercises: new Set(JSON.parse(localStorage.getItem('sql_completed_exercises') || '[]')),
    drafts: JSON.parse(localStorage.getItem('sql_exercise_drafts') || '{}')
  };

  const data = window.SQL_MASTERY_DATA || { modules: [], lessons: [], stats: {} };

  // --- 2. INIT ALASQL DATABASE & POSTGRESQL EXTENSIONS ---
  function initDatabase() {
    if (typeof alasql === 'undefined') {
      console.warn('AlaSQL not loaded; offline SQL execution will be limited.');
      return;
    }

    try {
      // Register custom PostgreSQL & Analytics functions in AlaSQL
      alasql.fn.DATE_TRUNC = function (part, dt) {
        if (!dt) return null;
        const str = String(dt);
        if (part === 'month') return str.substring(0, 7) + '-01';
        if (part === 'year') return str.substring(0, 4) + '-01-01';
        if (part === 'quarter') {
          const m = parseInt(str.substring(5, 7), 10);
          const qMonth = m <= 3 ? '01' : m <= 6 ? '04' : m <= 9 ? '07' : '10';
          return str.substring(0, 4) + '-' + qMonth + '-01';
        }
        if (part === 'day') return str.substring(0, 10);
        return str;
      };

      alasql.fn.EXTRACT = function (part, dt) {
        if (!dt) return null;
        const d = new Date(dt);
        if (isNaN(d)) return 0;
        if (part === 'YEAR') return d.getFullYear();
        if (part === 'MONTH') return d.getMonth() + 1;
        if (part === 'DAY') return d.getDate();
        if (part === 'DOW') return d.getDay();
        return 0;
      };

      alasql.fn.ROUND = function (num, decimals) {
        if (num === null || num === undefined) return null;
        return Number(Number(num).toFixed(decimals !== undefined ? decimals : 0));
      };

      alasql.fn.NULLIF = function (a, b) {
        return a === b ? null : a;
      };

      alasql.fn.COALESCE = function (...args) {
        for (let a of args) {
          if (a !== null && a !== undefined) return a;
        }
        return null;
      };

      alasql.fn.AGE = function (d1, d2) {
        const date1 = new Date(d1 || new Date());
        const date2 = new Date(d2);
        return Math.floor((date1 - date2) / (365.25 * 24 * 60 * 60 * 1000));
      };

      // Populate Seed Tables
      if (window.DB_SEED) {
        for (let tableName in window.DB_SEED) {
          try {
            alasql('DROP TABLE IF EXISTS ' + tableName);
            alasql('CREATE TABLE ' + tableName);
            alasql.tables[tableName].data = JSON.parse(JSON.stringify(window.DB_SEED[tableName]));
          } catch (e) {
            console.error('Error seeding table ' + tableName, e);
          }
        }
        console.log('Database initialized successfully with 9 tables.');
      }
    } catch (err) {
      console.error('Database initialization error:', err);
    }
  }

  // --- 3. SQL QUERY EXECUTOR & SANITIZER ---
  function sanitizePostgresToAlaSQL(query) {
    let clean = query;
    // Remove postgres casting: ::DATE, ::TEXT, ::INT, ::NUMERIC, ::JSONB
    clean = clean.replace(/::[A-Za-z0-9_]+/g, '');
    // Convert COUNT(*) FILTER (WHERE cond) to SUM(CASE WHEN cond THEN 1 ELSE 0 END)
    clean = clean.replace(/COUNT\s*\(\s*\*\s*\)\s*FILTER\s*\(\s*WHERE\s+([^)]+)\)/gi, 'SUM(CASE WHEN $1 THEN 1 ELSE 0 END)');
    clean = clean.replace(/COUNT\s*\(([^)]+)\)\s*FILTER\s*\(\s*WHERE\s+([^)]+)\)/gi, 'SUM(CASE WHEN $2 THEN 1 ELSE 0 END)');
    clean = clean.replace(/SUM\s*\(([^)]+)\)\s*FILTER\s*\(\s*WHERE\s+([^)]+)\)/gi, 'SUM(CASE WHEN $2 THEN $1 ELSE 0 END)');
    // Convert ILIKE to LIKE
    clean = clean.replace(/\bILIKE\b/gi, 'LIKE');
    // Remove NULLS LAST / NULLS FIRST
    clean = clean.replace(/\s+NULLS\s+(LAST|FIRST)/gi, '');
    // Replace STRING_AGG with GROUP_CONCAT
    clean = clean.replace(/\bSTRING_AGG\s*\(/gi, 'GROUP_CONCAT(');
    return clean;
  }

  function executeSQL(sqlQuery) {
    if (typeof alasql === 'undefined') {
      return { success: false, error: 'AlaSQL engine chưa sẵn sàng. Vui lòng tải lại trang.' };
    }

    const t0 = performance.now();
    try {
      const sanitized = sanitizePostgresToAlaSQL(sqlQuery);
      const res = alasql(sanitized);
      const t1 = performance.now();
      const timeMs = (t1 - t0).toFixed(1);

      let rows = [];
      let columns = [];

      if (Array.isArray(res)) {
        // If single array of objects
        if (res.length > 0 && typeof res[0] === 'object' && res[0] !== null) {
          rows = res;
          columns = Object.keys(rows[0]);
        } else if (res.length > 0 && Array.isArray(res[0])) {
          // Array of multiple statements result: take last query
          const lastRes = res[res.length - 1];
          if (Array.isArray(lastRes) && lastRes.length > 0 && typeof lastRes[0] === 'object') {
            rows = lastRes;
            columns = Object.keys(rows[0]);
          } else {
            rows = [{ result: JSON.stringify(lastRes) }];
            columns = ['result'];
          }
        } else {
          rows = res.map(v => ({ value: v }));
          columns = ['value'];
        }
      } else {
        rows = [{ result: String(res) }];
        columns = ['result'];
      }

      return {
        success: true,
        columns: columns,
        rows: rows,
        count: rows.length,
        timeMs: timeMs
      };
    } catch (err) {
      return {
        success: false,
        error: err.message || 'Lỗi cú pháp SQL hoặc truy vấn chưa được hỗ trợ.'
      };
    }
  }

  // --- 4. RENDERERS & HELPERS ---
  function showToast(message) {
    const container = document.getElementById('toast-container');
    if (!container) return;
    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<span>✓</span> <span>${message}</span>`;
    container.appendChild(toast);
    setTimeout(() => {
      toast.style.opacity = '0';
      setTimeout(() => toast.remove(), 300);
    }, 2400);
  }

  function copyToClipboard(text, msg = 'Đã sao chép vào bộ nhớ tạm!') {
    navigator.clipboard.writeText(text).then(() => {
      showToast(msg);
    }).catch(() => {
      // Fallback
      const ta = document.createElement('textarea');
      ta.value = text;
      document.body.appendChild(ta);
      ta.select();
      document.execCommand('copy');
      ta.remove();
      showToast(msg);
    });
  }

  function highlightSQL(code) {
    if (!code) return '';
    const keywords = [
      'SELECT', 'FROM', 'WHERE', 'JOIN', 'INNER', 'LEFT', 'RIGHT', 'FULL', 'OUTER', 'CROSS', 'ON',
      'GROUP BY', 'HAVING', 'ORDER BY', 'LIMIT', 'OFFSET', 'DISTINCT', 'AS', 'AND', 'OR', 'NOT',
      'IN', 'BETWEEN', 'LIKE', 'ILIKE', 'IS', 'NULL', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
      'WITH', 'RECURSIVE', 'OVER', 'PARTITION BY', 'ROWS', 'RANGE', 'PRECEDING', 'FOLLOWING', 'CURRENT ROW',
      'UNION', 'ALL', 'INTERSECT', 'EXCEPT', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE',
      'CREATE', 'TABLE', 'DROP', 'ALTER', 'INDEX', 'VIEW', 'CASCADE', 'PRIMARY KEY', 'FOREIGN KEY'
    ];
    const functions = [
      'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'ROUND', 'COALESCE', 'NULLIF', 'DATE_TRUNC', 'EXTRACT',
      'ROW_NUMBER', 'RANK', 'DENSE_RANK', 'NTILE', 'LAG', 'LEAD', 'FIRST_VALUE', 'LAST_VALUE',
      'STRING_AGG', 'CONCAT', 'AGE', 'EXISTS'
    ];

    let escaped = code
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');

    // Highlight comments
    escaped = escaped.replace(/(--[^\n]*)/g, '<span class="token-comment">$1</span>');
    // Highlight strings
    escaped = escaped.replace(/('(?:''|[^'\\]|\\.)*')/g, '<span class="token-string">$1</span>');
    // Highlight numbers
    escaped = escaped.replace(/\b(\d+(?:\.\d+)?)\b/g, '<span class="token-number">$1</span>');

    return escaped;
  }

  function formatCallouts(text) {
    if (!text) return '';
    return text.split('\n').map(line => {
      const stripped = line.trim();
      if (stripped.startsWith('💡 TẠI SAO') || stripped.startsWith('-- 💡 TẠI SAO')) {
        return `<div class="callout callout-why"><div class="callout-header">💡 TẠI SAO?</div><div>${escapeHTML(stripped.replace(/^(--\s*)?💡\s*TẠI SAO:?/, ''))}</div></div>`;
      }
      if (stripped.startsWith('⚠️ CẠM BẪY') || stripped.startsWith('-- ⚠️ CẠM BẪY')) {
        return `<div class="callout callout-warning"><div class="callout-header">⚠️ CẠM BẪY CẦN TRÁNH</div><div>${escapeHTML(stripped.replace(/^(--\s*)?⚠️\s*CẠM BẪY:?/, ''))}</div></div>`;
      }
      if (stripped.startsWith('🧠 CẦN NHỚ') || stripped.startsWith('-- 🧠 CẦN NHỚ')) {
        return `<div class="callout callout-remember"><div class="callout-header">🧠 ĐIỀU CỐT LÕI CẦN NHỚ</div><div>${escapeHTML(stripped.replace(/^(--\s*)?🧠\s*CẦN NHỚ:?/, ''))}</div></div>`;
      }
      if (stripped.startsWith('💬 CÁCH ĐỌC') || stripped.startsWith('-- 💬 CÁCH ĐỌC') || stripped.startsWith('💬 ĐỌC DÒNG NÀY')) {
        return `<div class="callout callout-read"><div class="callout-header">💬 CÁCH ĐỌC TƯ DUY TRUY VẤN</div><div>${escapeHTML(stripped.replace(/^(--\s*)?💬\s*(?:CÁCH ĐỌC|ĐỌC DÒNG NÀY):?/, ''))}</div></div>`;
      }
      return line;
    }).join('\n');
  }

  function escapeHTML(str) {
    if (!str) return '';
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // --- 5. APP CONTROLLER ---
  function updateTheme() {
    document.documentElement.setAttribute('data-theme', state.theme);
    localStorage.setItem('sql_theme', state.theme);
    const themeIcon = document.getElementById('theme-toggle-icon');
    if (themeIcon) {
      themeIcon.textContent = state.theme === 'dark' ? '☀️' : '🌙';
    }
  }

  function updateFontScale() {
    document.documentElement.style.setProperty('--font-scale', state.fontScale);
    localStorage.setItem('sql_font_scale', state.fontScale);
  }

  function updateProgress() {
    const total = data.lessons.length;
    const completed = state.completedLessons.size;
    const pct = total > 0 ? Math.round((completed / total) * 100) : 0;

    const fill = document.getElementById('progress-bar-fill');
    const text = document.getElementById('progress-text');
    if (fill) fill.style.width = pct + '%';
    if (text) text.textContent = `${completed}/${total} bài (${pct}%)`;

    localStorage.setItem('sql_completed_lessons', JSON.stringify(Array.from(state.completedLessons)));
    localStorage.setItem('sql_completed_exercises', JSON.stringify(Array.from(state.completedExercises)));
  }

  // --- 6. NAVIGATION & SIDEBAR RENDER ---
  function renderSidebar() {
    const container = document.getElementById('sidebar-content');
    if (!container) return;

    let html = '';
    const track = state.currentTrack;

    // Special tools group at the top
    html += `
      <div class="module-group">
        <div class="module-header" onclick="window.location.hash='#view/playground'">
          <div class="module-header-title">⚡ Phòng Lab SQL Tự Do</div>
        </div>
        <div class="module-header" onclick="window.location.hash='#view/cheatsheet'">
          <div class="module-header-title">📖 Cẩm Nang Tra Cứu (Cheatsheet)</div>
        </div>
        <div class="module-header" onclick="window.location.hash='#view/erd'">
          <div class="module-header-title">🗄️ Sơ Đồ CSDL Thực Thể (ERD)</div>
        </div>
      </div>
    `;

    data.modules.forEach(mod => {
      // Filter by track if needed
      const modLessons = data.lessons.filter(l => l.moduleId === mod.id);
      const filteredLessons = modLessons.filter(l => {
        if (track === 'All') return true;
        if (track === 'Foundation') return l.track === 'Foundation' || l.track === 'All';
        if (track === 'DA') return l.track === 'DA' || l.track === 'Foundation' || l.track === 'Projects' || l.track === 'Capstone';
        if (track === 'DE') return l.track === 'DE' || l.track === 'Foundation' || l.track === 'Projects' || l.track === 'Capstone';
        if (track === 'Practice') return l.isPractice;
        return true;
      });

      if (filteredLessons.length === 0) return;

      const completedCount = filteredLessons.filter(l => state.completedLessons.has(l.id)).length;

      html += `
        <div class="module-group" data-module-id="${mod.id}">
          <div class="module-header" onclick="toggleModule('${mod.id}')">
            <div class="module-header-title">
              <span>${mod.name}</span>
            </div>
            <span class="lesson-badge badge-theory">${completedCount}/${filteredLessons.length}</span>
          </div>
          <ul class="module-lessons" id="module-lessons-${mod.id}">
      `;

      filteredLessons.forEach(l => {
        const isCompleted = state.completedLessons.has(l.id);
        const isActive = state.currentLessonId === l.id;
        const badgeClass = l.isPractice ? (l.id.includes('exam') ? 'badge-exam' : 'badge-practice') : 'badge-theory';
        const badgeLabel = l.isPractice ? (l.id.includes('exam') ? 'Thi' : `${l.exerciseCount} bài`) : 'Lý thuyết';

        html += `
          <li class="lesson-item">
            <a href="#lesson/${l.id}" class="lesson-link ${isActive ? 'active' : ''} ${isCompleted ? 'completed' : ''}" id="nav-item-${l.id}">
              <div style="display:flex; align-items:center; gap:8px; overflow:hidden;">
                <span class="lesson-status-icon">${isCompleted ? '✓' : '○'}</span>
                <span style="white-space:nowrap; overflow:hidden; text-overflow:ellipsis;" title="${escapeHTML(l.title)}">${escapeHTML(l.title)}</span>
              </div>
              <span class="lesson-badge ${badgeClass}">${badgeLabel}</span>
            </a>
          </li>
        `;
      });

      html += `
          </ul>
        </div>
      `;
    });

    container.innerHTML = html;
  }

  window.toggleModule = function (modId) {
    const list = document.getElementById(`module-lessons-${modId}`);
    if (list) {
      list.style.display = list.style.display === 'none' ? 'block' : 'none';
    }
  };

  // --- 7. MAIN LESSON RENDERER ---
  function renderLesson(lessonId) {
    const lesson = data.lessons.find(l => l.id === lessonId);
    if (!lesson) {
      renderPlayground();
      return;
    }

    state.currentLessonId = lessonId;
    const isCompleted = state.completedLessons.has(lessonId);

    // Update active state in sidebar
    document.querySelectorAll('.lesson-link').forEach(el => el.classList.remove('active'));
    const navEl = document.getElementById(`nav-item-${lessonId}`);
    if (navEl) navEl.classList.add('active');

    const mainContainer = document.getElementById('main-content');
    if (!mainContainer) return;

    // Determine current tab
    let activeTab = state.currentTab;
    if (activeTab === 'auto' || (activeTab !== 'lesson' && activeTab !== 'practice' && activeTab !== 'raw')) {
      activeTab = lesson.isPractice && lesson.exercises.length > 0 ? 'practice' : 'lesson';
    }

    let html = `
      <div class="breadcrumb">
        <a href="#view/home">Trang chủ</a> &gt; <span>${escapeHTML(lesson.moduleName)}</span> &gt; <span>${escapeHTML(lesson.title)}</span>
      </div>

      <div class="lesson-header">
        <div class="lesson-title-row">
          <h1 class="lesson-title">${escapeHTML(lesson.title)}</h1>
          <div class="lesson-actions">
            <button class="btn-complete ${isCompleted ? 'active' : ''}" onclick="toggleCompleteLesson('${lesson.id}')">
              <span>${isCompleted ? '✓ Đã hoàn thành' : '○ Đánh dấu đã học'}</span>
            </button>
          </div>
        </div>

        <div class="lesson-meta">
          <span class="meta-pill">📁 ${escapeHTML(lesson.filename)}</span>
          <span class="meta-pill">🎯 Định hướng: <strong>${escapeHTML(lesson.track)}</strong></span>
          ${lesson.exerciseCount > 0 ? `<span class="meta-pill">✍️ ${lesson.exerciseCount} bài tập thực hành</span>` : ''}
        </div>
      </div>
    `;

    // Tabs navigation if file has exercises or is regular lesson
    if (lesson.exercises.length > 0) {
      html += `
        <div class="lesson-tabs">
          <button class="tab-btn ${activeTab === 'practice' ? 'active' : ''}" onclick="switchLessonTab('practice')">
            ✍️ Làm bài tập tương tác (${lesson.exercises.length} bài)
          </button>
          <button class="tab-btn ${activeTab === 'lesson' ? 'active' : ''}" onclick="switchLessonTab('lesson')">
            📖 Nội dung đầy đủ
          </button>
          <button class="tab-btn ${activeTab === 'raw' ? 'active' : ''}" onclick="switchLessonTab('raw')">
            💻 Mã nguồn SQL gốc
          </button>
        </div>
      `;
    }

    // TAB CONTENTS
    if (activeTab === 'practice' && lesson.exercises.length > 0) {
      html += renderExerciseWorkspace(lesson);
    } else if (activeTab === 'raw') {
      html += `
        <div class="code-container">
          <div class="code-header">
            <span>${escapeHTML(lesson.filename)}</span>
            <button class="btn-copy" onclick="copyCurrentLessonRaw()">Sao chép mã nguồn</button>
          </div>
          <pre><code>${highlightSQL(lesson.rawContent)}</code></pre>
        </div>
      `;
    } else {
      // Lecture / Theory view
      html += renderTheoryContent(lesson);
    }

    // Prev / Next Navigation Footer
    html += renderPrevNextFooter(lesson);

    mainContainer.innerHTML = html;
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }

  function renderTheoryContent(lesson) {
    if (lesson.isMarkdown) {
      // Render simple markdown formatted
      return `<div class="exercise-req-box" style="font-family: inherit; font-size: 1rem; line-height: 1.8;">${formatMarkdown(lesson.rawContent)}</div>`;
    }

    let contentHtml = '';
    const formatted = formatCallouts(lesson.rawContent);

    contentHtml += `
      <div class="code-container">
        <div class="code-header">
          <span>${escapeHTML(lesson.filename)} (Nhấn sao chép để paste vào DBeaver / DataGrip)</span>
          <button class="btn-copy" onclick="copyCurrentLessonRaw()">Sao chép bài học</button>
        </div>
        <pre><code>${highlightSQL(lesson.rawContent)}</code></pre>
      </div>
    `;

    return contentHtml;
  }

  function renderExerciseWorkspace(lesson) {
    let html = '';

    lesson.exercises.forEach((ex, idx) => {
      const isExCompleted = state.completedExercises.has(ex.id);
      const draftSQL = state.drafts[ex.id] || (ex.solution_sql ? '' : 'SELECT \n    *\nFROM customers\nLIMIT 10;');

      html += `
        <div class="exercise-card" id="card-${ex.id}">
          <div class="exercise-header">
            <div class="exercise-title-group">
              <span class="exercise-badge">${ex.level || 'Thực hành'}</span>
              <h2 class="exercise-title">${escapeHTML(ex.title)}</h2>
            </div>
            <button class="btn-complete ${isExCompleted ? 'active' : ''}" onclick="toggleCompleteExercise('${ex.id}')">
              <span>${isExCompleted ? '✓ Hoàn thành' : '○ Đánh dấu xong'}</span>
            </button>
          </div>

          <div class="exercise-body">
            <div class="exercise-section-title">📌 Đề bài &amp; Yêu cầu kinh doanh</div>
            <div class="exercise-req-box">${escapeHTML(ex.requirements || 'Lấy dữ liệu theo yêu cầu bên dưới.')}</div>

            ${ex.hints ? `
              <div class="exercise-section-title">💡 Gợi ý thực hiện</div>
              <div class="exercise-hint-box">${escapeHTML(ex.hints)}</div>
            ` : ''}

            ${ex.expected_output ? `
              <div class="exercise-section-title">📊 Kết quả đầu ra mong đợi (Expected Output)</div>
              <div class="expected-output-container">${escapeHTML(ex.expected_output)}</div>
            ` : ''}

            <!-- Interactive Editor -->
            <div class="editor-workspace">
              <div class="editor-toolbar">
                <span class="editor-label">💻 Khung Soạn Thảo SQL (Viết câu lệnh của bạn vào đây)</span>
                <div class="editor-actions">
                  <button class="btn-secondary" onclick="insertSolutionTemplate('${ex.id}')" title="Nạp gợi ý khung SELECT...FROM">Mẫu khung</button>
                  <button class="btn-secondary" onclick="resetExerciseDraft('${ex.id}')">Xóa làm lại</button>
                </div>
              </div>
              <textarea class="sql-textarea" id="editor-${ex.id}" placeholder="-- Gõ câu lệnh SQL của bạn tại đây...&#10;SELECT ..." oninput="saveExerciseDraft('${ex.id}')" onkeydown="handleEditorKeydown(event, '${ex.id}')">${escapeHTML(draftSQL)}</textarea>
              
              <div class="editor-footer-bar">
                <div style="font-size:0.8rem; color:var(--text-dim);">
                  Phím tắt: Nhấn <strong>Ctrl + Enter</strong> để chạy câu lệnh tức thì
                </div>
                <button class="btn-run-query" onclick="runExerciseQuery('${ex.id}')">
                  <span>▶️ Chạy câu lệnh</span>
                </button>
              </div>
            </div>

            <!-- Query Result Container -->
            <div id="result-${ex.id}" style="display:none;" class="query-result-box"></div>

            <!-- Official Solution Accordion -->
            ${ex.solution_sql ? `
              <div class="solution-container">
                <button class="solution-toggle-btn" onclick="toggleSolution('${ex.id}')">
                  <span id="sol-icon-${ex.id}">👁️</span> <span id="sol-text-${ex.id}">Xem lời giải mẫu chuẩn &amp; phân tích</span>
                </button>
                <div class="solution-content" id="sol-content-${ex.id}">
                  <div class="code-container" style="margin-top:10px;">
                    <div class="code-header">
                      <span>Lời giải chuẩn (PostgreSQL)</span>
                      <button class="btn-copy" onclick="copyCode(decodeURIComponent('${encodeURIComponent(ex.solution_sql)}'))">Sao chép đáp án</button>
                    </div>
                    <pre><code>${highlightSQL(ex.solution_sql)}</code></pre>
                  </div>
                  ${ex.notes && ex.notes.length > 0 ? `
                    <div style="margin-top:12px;">
                      ${ex.notes.map(n => `<div class="callout callout-remember" style="margin:8px 0;">${escapeHTML(n)}</div>`).join('')}
                    </div>
                  ` : ''}
                </div>
              </div>
            ` : ''}

          </div>
        </div>
      `;
    });

    return html;
  }

  function renderPrevNextFooter(currentLesson) {
    const currentIndex = data.lessons.findIndex(l => l.id === currentLesson.id);
    const prev = currentIndex > 0 ? data.lessons[currentIndex - 1] : null;
    const next = currentIndex < data.lessons.length - 1 ? data.lessons[currentIndex + 1] : null;

    return `
      <div class="lesson-nav-footer">
        ${prev ? `
          <a href="#lesson/${prev.id}" class="nav-page-btn">
            <span class="nav-label">← Bài trước</span>
            <span class="nav-title">${escapeHTML(prev.title)}</span>
          </a>
        ` : '<div></div>'}
        ${next ? `
          <a href="#lesson/${next.id}" class="nav-page-btn" style="text-align: right; margin-left: auto;">
            <span class="nav-label">Bài tiếp theo →</span>
            <span class="nav-title">${escapeHTML(next.title)}</span>
          </a>
        ` : '<div></div>'}
      </div>
    `;
  }

  // --- 8. EXERCISE WORKSPACE ACTIONS ---
  window.handleEditorKeydown = function (e, exId) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      runExerciseQuery(exId);
    }
  };

  window.saveExerciseDraft = function (exId) {
    const ta = document.getElementById(`editor-${exId}`);
    if (ta) {
      state.drafts[exId] = ta.value;
      localStorage.setItem('sql_exercise_drafts', JSON.stringify(state.drafts));
    }
  };

  window.resetExerciseDraft = function (exId) {
    const ta = document.getElementById(`editor-${exId}`);
    if (ta) {
      ta.value = '';
      saveExerciseDraft(exId);
      const resBox = document.getElementById(`result-${exId}`);
      if (resBox) resBox.style.display = 'none';
      showToast('Đã xóa câu lệnh làm lại.');
    }
  };

  window.insertSolutionTemplate = function (exId) {
    const ta = document.getElementById(`editor-${exId}`);
    if (ta) {
      ta.value = `SELECT \n    \nFROM \nWHERE \nORDER BY ;`;
      saveExerciseDraft(exId);
      ta.focus();
    }
  };

  window.runExerciseQuery = function (exId) {
    const ta = document.getElementById(`editor-${exId}`);
    if (!ta) return;
    const sql = ta.value.trim();
    if (!sql) {
      showToast('Vui lòng gõ câu lệnh SQL trước khi chạy!');
      return;
    }

    const resBox = document.getElementById(`result-${exId}`);
    if (!resBox) return;

    resBox.style.display = 'block';
    resBox.innerHTML = '<div style="padding:14px; color:var(--text-dim);">⏳ Đang thực thi truy vấn...</div>';

    setTimeout(() => {
      const outcome = executeSQL(sql);
      if (!outcome.success) {
        resBox.innerHTML = `
          <div class="result-header">
            <span style="color:var(--accent-rose); font-weight:bold;">❌ Lỗi thực thi</span>
          </div>
          <div class="query-error">${escapeHTML(outcome.error)}</div>
        `;
        return;
      }

      let tableHtml = `
        <div class="result-header">
          <span>✓ Kết quả thực thi (${outcome.count} dòng trong ${outcome.timeMs}ms)</span>
          <span style="font-size:0.75rem;">Engine: AlaSQL (In-Memory)</span>
        </div>
        <div class="result-table-wrapper">
          <table class="sql-table">
            <thead>
              <tr>
                ${outcome.columns.map(c => `<th>${escapeHTML(c)}</th>`).join('')}
              </tr>
            </thead>
            <tbody>
              ${outcome.rows.slice(0, 100).map(row => `
                <tr>
                  ${outcome.columns.map(c => {
                    const val = row[c];
                    return `<td>${val === null ? '<em style="color:var(--text-dim)">NULL</em>' : escapeHTML(String(val))}</td>`;
                  }).join('')}
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;

      if (outcome.rows.length > 100) {
        tableHtml += `<div style="padding:8px 12px; font-size:0.8rem; color:var(--text-dim); text-align:center;">Đã hiển thị 100 / ${outcome.rows.length} dòng kết quả đầu tiên.</div>`;
      }

      resBox.innerHTML = tableHtml;
    }, 30);
  };

  window.toggleSolution = function (exId) {
    const content = document.getElementById(`sol-content-${exId}`);
    const icon = document.getElementById(`sol-icon-${exId}`);
    const text = document.getElementById(`sol-text-${exId}`);
    if (!content) return;

    if (content.classList.contains('open')) {
      content.classList.remove('open');
      if (icon) icon.textContent = '👁️';
      if (text) text.textContent = 'Xem lời giải mẫu chuẩn & phân tích';
    } else {
      content.classList.add('open');
      if (icon) icon.textContent = '🙈';
      if (text) text.textContent = 'Ẩn lời giải mẫu';
    }
  };

  window.toggleCompleteLesson = function (lessonId) {
    if (state.completedLessons.has(lessonId)) {
      state.completedLessons.delete(lessonId);
      showToast('Đã bỏ đánh dấu hoàn thành bài này.');
    } else {
      state.completedLessons.add(lessonId);
      showToast('Chúc mừng! Đã hoàn thành bài học.');
    }
    updateProgress();
    renderLesson(lessonId);
    renderSidebar();
  };

  window.toggleCompleteExercise = function (exId) {
    if (state.completedExercises.has(exId)) {
      state.completedExercises.delete(exId);
      showToast('Đã bỏ đánh dấu hoàn thành bài tập.');
    } else {
      state.completedExercises.add(exId);
      showToast('Chúc mừng! Đã giải xong bài tập này.');
    }
    updateProgress();
    const card = document.getElementById(`card-${exId}`);
    if (card) {
      const btn = card.querySelector('.btn-complete');
      if (btn) {
        btn.classList.toggle('active', state.completedExercises.has(exId));
        btn.querySelector('span').textContent = state.completedExercises.has(exId) ? '✓ Hoàn thành' : '○ Đánh dấu xong';
      }
    }
  };

  window.switchLessonTab = function (tabName) {
    state.currentTab = tabName;
    renderLesson(state.currentLessonId);
  };

  window.copyCurrentLessonRaw = function () {
    const lesson = data.lessons.find(l => l.id === state.currentLessonId);
    if (lesson) copyToClipboard(lesson.rawContent);
  };

  window.copyCode = function (code) {
    copyToClipboard(code);
  };

  // --- 9. SQL PLAYGROUND / LAB VIEW ---
  function renderPlayground() {
    const mainContainer = document.getElementById('main-content');
    if (!mainContainer) return;

    let tablesListHtml = '';
    if (window.DB_SCHEMA) {
      for (let t in window.DB_SCHEMA) {
        const cols = window.DB_SCHEMA[t];
        tablesListHtml += `
          <div class="schema-table-item">
            <div class="schema-table-name" onclick="loadTablePreset('${t}')">
              <span>📋 ${t}</span>
              <span style="font-size:0.75rem; color:var(--text-dim);">${cols.length} cột</span>
            </div>
            <ul class="schema-cols-list">
              ${cols.slice(0, 6).map(c => `<li>• ${escapeHTML(c.name)} <span style="color:var(--text-dim)">(${escapeHTML(c.type)})</span></li>`).join('')}
              ${cols.length > 6 ? `<li>... +${cols.length - 6} cột khác</li>` : ''}
            </ul>
          </div>
        `;
      }
    }

    const defaultPlaygroundQuery = `-- PHÒNG LAB SQL TỰ DO: Viết câu lệnh SQL bất kỳ để khám phá dữ liệu E-commerce
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name AS ho_ten,
    c.city,
    COUNT(o.order_id) AS so_don_hang
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.city
ORDER BY so_don_hang DESC;`;

    mainContainer.innerHTML = `
      <div class="lesson-header">
        <h1 class="lesson-title">⚡ Phòng Lab SQL Tự Do (Playground)</h1>
        <p style="color:var(--text-muted); margin-top:6px;">Môi trường thực thi SQL trực tiếp trên RAM trình duyệt (100% Offline). Bạn có thể tự do truy vấn 9 bảng dữ liệu E-commerce mẫu.</p>
      </div>

      <div class="playground-grid">
        <div class="schema-panel">
          <div style="font-weight:700; margin-bottom:12px; font-size:0.95rem;">🗄️ Cấu Trúc Bảng (9 Bảng)</div>
          ${tablesListHtml}
        </div>

        <div>
          <div class="editor-workspace">
            <div class="editor-toolbar">
              <span class="editor-label">💻 SQL Console</span>
              <div class="editor-actions">
                <button class="btn-secondary" onclick="loadPlaygroundPreset(1)">Mẫu: Doanh thu theo tháng</button>
                <button class="btn-secondary" onclick="loadPlaygroundPreset(2)">Mẫu: Top 5 Sản Phẩm</button>
                <button class="btn-secondary" onclick="resetPlayground()">Xóa trắng</button>
              </div>
            </div>
            <textarea class="sql-textarea" id="playground-editor" style="height:200px;" onkeydown="handlePlaygroundKeydown(event)">${escapeHTML(defaultPlaygroundQuery)}</textarea>
            
            <div class="editor-footer-bar">
              <div style="font-size:0.8rem; color:var(--text-dim);">
                Phím tắt: Nhấn <strong>Ctrl + Enter</strong> để chạy câu lệnh
              </div>
              <button class="btn-run-query" onclick="runPlaygroundQuery()">
                <span>▶️ Chạy câu lệnh</span>
              </button>
            </div>
          </div>

          <div id="playground-result" class="query-result-box" style="display:none;"></div>
        </div>
      </div>
    `;

    // Auto-run default query on open
    setTimeout(() => runPlaygroundQuery(), 100);
  }

  window.handlePlaygroundKeydown = function (e) {
    if ((e.ctrlKey || e.metaKey) && e.key === 'Enter') {
      e.preventDefault();
      runPlaygroundQuery();
    }
  };

  window.loadTablePreset = function (tableName) {
    const ed = document.getElementById('playground-editor');
    if (ed) {
      ed.value = `SELECT * \nFROM ${tableName} \nLIMIT 20;`;
      runPlaygroundQuery();
    }
  };

  window.loadPlaygroundPreset = function (type) {
    const ed = document.getElementById('playground-editor');
    if (!ed) return;
    if (type === 1) {
      ed.value = `SELECT 
    DATE_TRUNC('month', order_date) AS sales_month,
    COUNT(order_id) AS total_orders,
    SUM(shipping_fee) AS total_shipping
FROM orders
WHERE order_status = 'Completed'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY sales_month;`;
    } else if (type === 2) {
      ed.value = `SELECT 
    p.product_id,
    p.product_name,
    p.unit_price,
    SUM(oi.quantity) AS total_quantity_sold
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.unit_price
ORDER BY total_quantity_sold DESC
LIMIT 5;`;
    }
    runPlaygroundQuery();
  };

  window.resetPlayground = function () {
    const ed = document.getElementById('playground-editor');
    if (ed) {
      ed.value = 'SELECT \n    *\nFROM customers\nLIMIT 10;';
      ed.focus();
    }
  };

  window.runPlaygroundQuery = function () {
    const ed = document.getElementById('playground-editor');
    if (!ed) return;
    const sql = ed.value.trim();
    if (!sql) return;

    const resBox = document.getElementById('playground-result');
    if (!resBox) return;

    resBox.style.display = 'block';
    resBox.innerHTML = '<div style="padding:14px; color:var(--text-dim);">⏳ Đang thực thi...</div>';

    setTimeout(() => {
      const outcome = executeSQL(sql);
      if (!outcome.success) {
        resBox.innerHTML = `
          <div class="result-header">
            <span style="color:var(--accent-rose); font-weight:bold;">❌ Lỗi thực thi</span>
          </div>
          <div class="query-error">${escapeHTML(outcome.error)}</div>
        `;
        return;
      }

      resBox.innerHTML = `
        <div class="result-header">
          <span>✓ Kết quả thực thi (${outcome.count} dòng trong ${outcome.timeMs}ms)</span>
          <button class="btn-copy" onclick="copyTableCSV()">Xuất CSV</button>
        </div>
        <div class="result-table-wrapper">
          <table class="sql-table" id="playground-table">
            <thead>
              <tr>
                ${outcome.columns.map(c => `<th>${escapeHTML(c)}</th>`).join('')}
              </tr>
            </thead>
            <tbody>
              ${outcome.rows.map(row => `
                <tr>
                  ${outcome.columns.map(c => `<td>${row[c] === null ? '<em style="color:var(--text-dim)">NULL</em>' : escapeHTML(String(row[c]))}</td>`).join('')}
                </tr>
              `).join('')}
            </tbody>
          </table>
        </div>
      `;
    }, 20);
  };

  window.copyTableCSV = function () {
    showToast('Đã xuất dữ liệu kết quả!');
  };

  // --- 10. ERD & CHEATSHEET VIEWS ---
  function renderERDView() {
    const mainContainer = document.getElementById('main-content');
    if (!mainContainer) return;

    let tablesHtml = '';
    if (window.DB_SCHEMA) {
      for (let t in window.DB_SCHEMA) {
        const cols = window.DB_SCHEMA[t];
        tablesHtml += `
          <div class="erd-card">
            <div class="erd-card-header">📊 ${t.toUpperCase()}</div>
            <div>
              ${cols.map(c => {
                const isPk = c.raw.toUpperCase().includes('PRIMARY KEY');
                const isFk = c.raw.toUpperCase().includes('REFERENCES');
                return `
                  <div class="erd-field-row">
                    <span class="${isPk ? 'erd-pk' : isFk ? 'erd-fk' : ''}">
                      ${isPk ? '🔑 ' : isFk ? '🔗 ' : ''}${escapeHTML(c.name)}
                    </span>
                    <span style="color:var(--text-dim); font-size:0.75rem;">${escapeHTML(c.type)}</span>
                  </div>
                `;
              }).join('')}
            </div>
          </div>
        `;
      }
    }

    mainContainer.innerHTML = `
      <div class="lesson-header">
        <h1 class="lesson-title">🗄️ Sơ Đồ Cơ Sở Dữ Liệu Thực Thể (ERD)</h1>
        <p style="color:var(--text-muted); margin-top:6px;">Mô hình dữ liệu quan hệ mô phỏng hệ thống E-commerce đa kênh &amp; Web Analytics gồm 9 bảng chuẩn hóa.</p>
      </div>

      <div class="erd-grid">
        ${tablesHtml}
      </div>

      <div style="margin-top:32px;">
        <h2 style="font-size:1.2rem; margin-bottom:12px;">🔗 Mối Quan Hệ Giữa Các Bảng (Relationships)</h2>
        <div class="exercise-req-box" style="font-family:var(--font-mono); font-size:0.88rem; line-height:1.7;">
CATEGORIES   (1) --- (N) CATEGORIES     [parent_category_id -> category_id]
CATEGORIES   (1) --- (N) PRODUCTS       [category_id -> category_id]
CUSTOMERS    (1) --- (N) ORDERS         [customer_id -> customer_id]
CUSTOMERS    (1) --- (N) WEB_EVENTS     [customer_id -> customer_id]
EMPLOYEES    (1) --- (N) EMPLOYEES      [manager_id -> employee_id]
ORDERS       (1) --- (N) ORDER_ITEMS    [order_id -> order_id]
PRODUCTS     (1) --- (N) ORDER_ITEMS    [product_id -> product_id]
ORDERS       (1) --- (N) PAYMENTS       [order_id -> order_id]
PRODUCTS     (1) --- (N) INVENTORY_LOGS [product_id -> product_id]
        </div>
      </div>
    `;
  }

  function renderCheatsheetView() {
    const mainContainer = document.getElementById('main-content');
    if (!mainContainer) return;

    mainContainer.innerHTML = `
      <div class="lesson-header">
        <h1 class="lesson-title">📖 Cẩm Nang Tra Cứu Nhanh SQL (Cheatsheet)</h1>
        <p style="color:var(--text-muted); margin-top:6px;">Bảng tra cứu tốc hành thứ tự thực thi, các hàm cửa sổ, kiểu Join và mẹo tối ưu hiệu năng để xem khi đi làm.</p>
      </div>

      <div class="cheatsheet-grid">
        <div class="cheat-card">
          <h3>⚡ Thứ Tự Thực Thi Logical (Execution Order)</h3>
          <p style="font-size:0.85rem; color:var(--text-muted); margin-bottom:10px;">Thứ tự database đọc và xử lý câu lệnh SQL trong thực tế:</p>
          <div style="font-family:var(--font-mono); font-size:0.85rem; background:var(--code-bg); padding:12px; border-radius:var(--radius-sm); line-height:1.8;">
1. <strong>FROM / JOIN</strong> &nbsp;&nbsp;(Chọn nguồn &amp; kết bảng)<br>
2. <strong>WHERE</strong> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Lọc từng dòng thô)<br>
3. <strong>GROUP BY</strong> &nbsp;&nbsp;&nbsp;&nbsp;(Gom nhóm bản ghi)<br>
4. <strong>HAVING</strong> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Lọc sau gom nhóm)<br>
5. <strong>SELECT</strong> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(Chiếu cột &amp; tính toán)<br>
6. <strong>DISTINCT</strong> &nbsp;&nbsp;&nbsp;&nbsp;(Khử các dòng trùng)<br>
7. <strong>ORDER BY</strong> &nbsp;&nbsp;&nbsp;&nbsp;(Sắp xếp kết quả)<br>
8. <strong>LIMIT / OFFSET</strong> (Phân trang kết quả)
          </div>
          <div class="callout callout-warning" style="margin-top:10px; font-size:0.82rem;">
            ⚠️ <strong>LƯU Ý:</strong> Alias đặt ở SELECT <em>không dùng được</em> trong WHERE vì WHERE chạy trước SELECT!
          </div>
        </div>

        <div class="cheat-card">
          <h3>🔗 Ma Trận Các Kiểu JOIN</h3>
          <div style="font-family:var(--font-mono); font-size:0.82rem; line-height:1.7;">
            <p><strong>INNER JOIN</strong>: Chỉ lấy giao điểm (khớp cả 2 bảng).</p>
            <p><strong>LEFT JOIN</strong>: Giữ toàn bộ bảng trái + thông tin bảng phải (nếu không có thì NULL).</p>
            <p><strong>FULL OUTER JOIN</strong>: Giữ toàn bộ dữ liệu cả 2 bên.</p>
            <p><strong>CROSS JOIN</strong>: Tích Descartes (M dòng x N dòng).</p>
            <p><strong>ANTI-JOIN (NOT EXISTS)</strong>: Tìm các bản ghi bảng A KHÔNG CÓ trong bảng B.</p>
            <p><strong>LATERAL JOIN</strong>: Cho phép subquery tham chiếu từng dòng của bảng ngoài.</p>
          </div>
        </div>

        <div class="cheat-card">
          <h3>🪟 Window Functions Cần Nhớ</h3>
          <div style="font-family:var(--font-mono); font-size:0.82rem; line-height:1.7;">
            <p><strong>ROW_NUMBER()</strong>: Đánh số thứ tự tăng dần duy nhất (1, 2, 3, 4).</p>
            <p><strong>RANK()</strong>: Đồng hạng thì nhảy cách bậc (1, 2, 2, 4).</p>
            <p><strong>DENSE_RANK()</strong>: Đồng hạng không nhảy cách bậc (1, 2, 2, 3).</p>
            <p><strong>LAG(col, 1)</strong>: Lấy giá trị dòng liền trước (tính tăng trưởng).</p>
            <p><strong>LEAD(col, 1)</strong>: Lấy giá trị dòng liền sau.</p>
            <p><strong>SUM(x) OVER (PARTITION BY ... ORDER BY ...)</strong>: Tính tổng tích lũy (Running Total).</p>
          </div>
        </div>

        <div class="cheat-card">
          <h3>⏱️ Xử Lý Thời Gian Phổ Biến</h3>
          <div style="font-family:var(--font-mono); font-size:0.82rem; line-height:1.7;">
            <p><strong>DATE_TRUNC('month', order_date)</strong>: Cắt cụt ngày về đầu tháng.</p>
            <p><strong>EXTRACT(YEAR FROM order_date)</strong>: Lấy riêng năm / tháng / quý.</p>
            <p><strong>AGE(CURRENT_DATE, birth_date)</strong>: Tính khoảng cách tuổi tác chính xác.</p>
            <p><strong>NOW() - INTERVAL '30 days'</strong>: Lùi thời gian về 30 ngày trước.</p>
          </div>
        </div>
      </div>
    `;
  }

  function formatMarkdown(md) {
    if (!md) return '';
    return md
      .replace(/^### (.*$)/gim, '<h3 style="margin:16px 0 8px;">$1</h3>')
      .replace(/^## (.*$)/gim, '<h2 style="margin:20px 0 10px; border-bottom:1px solid var(--border-color); padding-bottom:6px;">$1</h2>')
      .replace(/^# (.*$)/gim, '<h1 style="margin:24px 0 12px;">$1</h1>')
      .replace(/\*\*(.*?)\*\*/gim, '<strong>$1</strong>')
      .replace(/\*(.*?)\*/gim, '<em>$1</em>')
      .replace(/`([^`]+)`/gim, '<code style="background:var(--code-bg); padding:2px 6px; border-radius:4px; font-family:var(--font-mono); font-size:0.9em;">$1</code>')
      .replace(/\n\n/gim, '<br><br>');
  }

  // --- 11. GLOBAL SEARCH MODAL (Ctrl + K) ---
  function initSearch() {
    const modal = document.getElementById('search-modal');
    const input = document.getElementById('search-input');
    const resultsContainer = document.getElementById('search-results');

    window.openSearch = function () {
      if (modal) {
        modal.classList.add('open');
        if (input) {
          input.value = '';
          input.focus();
          renderSearchResults('');
        }
      }
    };

    window.closeSearch = function () {
      if (modal) modal.classList.remove('open');
    };

    if (modal) {
      modal.addEventListener('click', function (e) {
        if (e.target === modal) closeSearch();
      });
    }

    if (input) {
      input.addEventListener('input', function () {
        renderSearchResults(input.value.trim().toLowerCase());
      });
    }

    document.addEventListener('keydown', function (e) {
      if ((e.ctrlKey || e.metaKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault();
        openSearch();
      } else if (e.key === 'Escape') {
        closeSearch();
      }
    });

    function renderSearchResults(q) {
      if (!resultsContainer) return;
      if (!q) {
        resultsContainer.innerHTML = '<div style="padding:16px; color:var(--text-dim); text-align:center;">Gõ từ khóa để tìm kiếm (ví dụ: <code>ROW_NUMBER</code>, <code>JOIN</code>, <code>SCD</code>, <code>DISTINCT ON</code>)...</div>';
        return;
      }

      const matches = [];

      // Search lessons
      data.lessons.forEach(l => {
        const inTitle = l.title.toLowerCase().includes(q);
        const inDesc = l.desc.toLowerCase().includes(q);
        const inRaw = l.rawContent.toLowerCase().includes(q);

        if (inTitle || inDesc || inRaw) {
          matches.push({
            type: 'lesson',
            id: l.id,
            title: l.title,
            module: l.moduleName,
            desc: inTitle ? l.desc : (inDesc ? l.desc : 'Tìm thấy khớp trong nội dung bài học hoặc câu lệnh SQL.')
          });
        }

        // Search exercises inside lesson
        l.exercises.forEach(ex => {
          if (ex.title.toLowerCase().includes(q) || ex.requirements.toLowerCase().includes(q) || ex.solution_sql.toLowerCase().includes(q)) {
            matches.push({
              type: 'exercise',
              lessonId: l.id,
              exId: ex.id,
              title: `✍️ ${ex.title}`,
              module: l.title,
              desc: ex.requirements.substring(0, 100) + '...'
            });
          }
        });
      });

      if (matches.length === 0) {
        resultsContainer.innerHTML = `<div style="padding:20px; color:var(--text-dim); text-align:center;">Không tìm thấy kết quả nào cho "<strong>${escapeHTML(q)}</strong>".</div>`;
        return;
      }

      resultsContainer.innerHTML = matches.slice(0, 15).map(m => `
        <div class="search-result-item" onclick="selectSearchResult('${m.type}', '${m.type === 'exercise' ? m.lessonId : m.id}', '${m.exId || ''}')">
          <div class="search-result-title">${escapeHTML(m.title)}</div>
          <div style="font-size:0.75rem; color:var(--text-dim);">${escapeHTML(m.module)}</div>
          <div class="search-result-desc">${escapeHTML(m.desc)}</div>
        </div>
      `).join('');
    }

    window.selectSearchResult = function (type, lessonId, exId) {
      closeSearch();
      window.location.hash = `#lesson/${lessonId}`;
      if (type === 'exercise' && exId) {
        setTimeout(() => {
          const el = document.getElementById(`card-${exId}`);
          if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }, 200);
      }
    };
  }

  // --- 12. ROUTING ---
  function handleRoute() {
    const hash = window.location.hash || '#view/home';
    const parts = hash.slice(1).split('/');
    const action = parts[0];
    const param = parts[1];

    if (action === 'lesson' && param) {
      renderLesson(param);
    } else if (action === 'view') {
      if (param === 'playground') {
        renderPlayground();
      } else if (param === 'cheatsheet') {
        renderCheatsheetView();
      } else if (param === 'erd') {
        renderERDView();
      } else {
        // Default to first lesson
        const first = data.lessons[0];
        if (first) {
          window.location.hash = `#lesson/${first.id}`;
        }
      }
    } else {
      const first = data.lessons[0];
      if (first) {
        window.location.hash = `#lesson/${first.id}`;
      }
    }

    renderSidebar();
  }

  // --- 13. APP STARTUP ---
  document.addEventListener('DOMContentLoaded', function () {
    updateTheme();
    updateFontScale();
    initDatabase();
    initSearch();
    updateProgress();

    // Mobile drawer toggle & overlay
    const toggleBtn = document.getElementById('mobile-toggle');
    const sidebar = document.getElementById('sidebar');
    const overlay = document.getElementById('sidebar-overlay');

    function closeMobileSidebar() {
      if (sidebar) sidebar.classList.remove('mobile-open');
      if (overlay) overlay.classList.remove('active');
    }

    function openMobileSidebar() {
      if (sidebar) sidebar.classList.add('mobile-open');
      if (overlay) overlay.classList.add('active');
    }

    if (toggleBtn) {
      toggleBtn.addEventListener('click', () => {
        if (sidebar && sidebar.classList.contains('mobile-open')) {
          closeMobileSidebar();
        } else {
          openMobileSidebar();
        }
      });
    }

    if (overlay) {
      overlay.addEventListener('click', closeMobileSidebar);
    }

    // Auto-close sidebar on mobile when a link is clicked
    document.addEventListener('click', (e) => {
      if (e.target.closest('.lesson-link') || e.target.closest('.module-header')) {
        if (window.innerWidth <= 900) {
          closeMobileSidebar();
        }
      }
    });

    // Theme toggle button
    const themeBtn = document.getElementById('theme-toggle');
    if (themeBtn) {
      themeBtn.addEventListener('click', () => {
        state.theme = state.theme === 'dark' ? 'light' : 'dark';
        updateTheme();
      });
    }

    // Font size toggles
    const fontInc = document.getElementById('font-increase');
    const fontDec = document.getElementById('font-decrease');
    if (fontInc) {
      fontInc.addEventListener('click', () => {
        state.fontScale = Math.min(1.4, state.fontScale + 0.1);
        updateFontScale();
      });
    }
    if (fontDec) {
      fontDec.addEventListener('click', () => {
        state.fontScale = Math.max(0.85, state.fontScale - 0.1);
        updateFontScale();
      });
    }

    // Track filter pills
    document.querySelectorAll('.track-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        document.querySelectorAll('.track-btn').forEach(b => b.classList.remove('active'));
        btn.classList.add('active');
        state.currentTrack = btn.dataset.track;
        renderSidebar();
      });
    });

    // Register PWA Service Worker for 100% Offline Smartphone Experience
    if ('serviceWorker' in navigator && window.location.protocol.startsWith('http')) {
      navigator.serviceWorker.register('./sw.js')
        .then(() => console.log('PWA Service Worker registered'))
        .catch(err => console.log('Service Worker setup skipped in file:// mode', err));
    }

    window.addEventListener('hashchange', handleRoute);
    handleRoute();
  });


})();
