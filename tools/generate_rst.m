function generate_rst(mFile, rstFolder, targets, knownNames)
% GENERATE_RST  Create a Sphinx RST page from a MATLAB help header.
%
% Usage:
%   generate_rst(mFile, rstFolder)
%   generate_rst(mFile, rstFolder, targets)
%   generate_rst(mFile, rstFolder, targets, knownNames)
%
% Inputs:
%   MFILE      - Full path to the .m file.
%   RSTFOLDER  - Folder the .rst file is written to (created if absent).
%   TARGETS    - Optional containers.Map from function name to the :doc:
%                target to use for it. Sphinx resolves a relative target
%                against the folder the PAGE lives in, so a demo page needs
%                '../modules/fmri_x' where a function page needs 'fmri_x'.
%   KNOWNNAMES - Optional cellstr of every .m file in the toolbox. A "See
%                also" naming one of these but absent from TARGETS is a
%                private helper or a script: rendered as literal text without
%                a warning. A name in neither is reported.
%
% Notes:
% Notes:
%   The converter:
%     1. Reads help blocks from both functions and scripts.
%     2. Escapes RST markup in prose while preserving code blocks.
%     3. Converts all-caps help headings into separate sections.
%     4. Ends code sections when unindented prose begins.
%     5. Recognises quoted name-value arguments as input entries.
%     6. Reflows notes as paragraphs while preserving lists, fields and
%        indented code.
%
% See also: batch_generate

if nargin < 3, targets = containers.Map('KeyType','char','ValueType','char'); end
if nargin < 4, knownNames = {}; end

% Match one or more comma-separated names followed by ' - '. Quotes are
% allowed so name-value arguments are recognised as separate entries.
NAMEPAT  = '[A-Za-z0-9_.''\[\]()]+(?:\s*,\s*[A-Za-z0-9_.''\[\]()]+)*';
ITEMPAT  = ['^(' NAMEPAT ')\s+-\s'];
% Match aligned field lines such as "Dimensions  : 91 x 109 x 91". The space
% before the colon distinguishes them from ordinary prose such as "Default:".
FIELDPAT = '^\S[^:]{0,22}\s:\s+\S';
% Match "Name - description" definitions whose names may be short expressions,
% such as "atanh(R) * sqrt(DF-3)".
DEFPAT   = '^\S.{0,40}?\s+-\s+\S';
LBL      = '<<<LABEL>>>';
NST      = '<<<NEST>>>';

if ~isfolder(rstFolder), mkdir(rstFolder); end
[~, funcName] = fileparts(mFile);

fid = fopen(mFile, 'r');
if fid == -1
    error('generate_rst:cannotRead', 'Could not open file: %s', mFile);
end
lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
lines = lines{1};

S = struct('description', {{}}, 'usage', {{}}, 'inputs', {{}}, ...
           'outputs', {{}}, 'examples', {{}}, 'notes', {{}}, ...
           'references', {{}}, 'seealso', {{}}, ...
           'inputs_tail', {{}}, 'outputs_tail', {{}});
itemIndent = struct('inputs', -1, 'outputs', -1);  % indent of the first item
inTail     = struct('inputs', false, 'outputs', false);
prevBlank  = true;
cusTitle = {};  cusLines = {};  cusAfter = [];

section      = 'description';
curCustom    = 0;        % 0 = none, else index into cus*
seenExamples = false;
inDocBlock   = false;
started      = false;

heads = { 'usage:',       'usage'
          'inputs:',      'inputs'
          'input:',       'inputs'
          'optional',     'inputs'
          'outputs:',     'outputs'
          'output:',      'outputs'
          'examples:',    'examples'
          'example:',     'examples'
          'description:', 'description'
          'notes:',       'notes'
          'note:',        'notes'
          'references:',  'references'
          'reference:',   'references'
          'see also:',    'seealso' };

for i = 1:numel(lines)
    raw  = lines{i};
    line = strtrim(raw);

    if ~inDocBlock
        if startsWith(line, 'function')
            inDocBlock = true;  continue
        elseif startsWith(line, '%')
            inDocBlock = true;
        elseif isempty(line)
            continue
        else
            break
        end
    end

    if ~startsWith(line, '%')
        if started, break, else, continue, end
    end
    started = true;

    body    = deblank(regexprep(raw, '^\s*%\s?', '', 'once'));
    content = strtrim(body);
    indent  = numel(body) - numel(regexprep(body, '^\s*', '', 'once'));

    if isempty(content)
        % Paragraph break; never the first line of a block.
        if curCustom > 0
            if ~isempty(cusLines{curCustom}), cusLines{curCustom}{end+1} = ''; end
        elseif any(strcmp(section, {'inputs','outputs'})) && inTail.(section) ...
                && ~isempty(S.([section '_tail']))
            S.([section '_tail']){end+1} = '';
        elseif any(strcmp(section, {'description','notes','usage','examples'})) ...
                && ~isempty(S.(section))
            S.(section){end+1} = '';
        end
        prevBlank = true;
        continue
    end

    if ~isempty(regexp(content, '^[-=#*_]{3,}$', 'once')), continue, end
    wasBlank  = prevBlank;
    prevBlank = false;

    low = lower(content);
    hit = false;
    for h = 1:size(heads, 1)
        if startsWith(low, heads{h,1})
            curCustom = 0;
            section   = heads{h,2};
            if strcmp(section, 'examples'), seenExamples = true; end
            rest = strtrim(content(numel(heads{h,1})+1:end));
            rest = regexprep(rest, '^\([^)]*\):?\s*', '');
            if ~isempty(rest)
                if any(strcmp(section, {'inputs','outputs'})) ...
                        && isempty(regexp(rest, '\s-\s', 'once'))
                    % "Optional name-value pairs:" is a group label, not an
                    % entry (rule 5).
                    S.(section){end+1} = [LBL regexprep(rest, ':$', '')];
                else
                    S.(section){end+1} = rest; %#ok<*AGROW>
                end
            end
            hit = true; break
        end
    end
    if hit, continue, end

    % Look ahead one line, for the heading test.
    nxtBody = '';
    if i < numel(lines)
        nxtRaw = lines{i+1};
        if startsWith(strtrim(nxtRaw), '%')
            nxtBody = deblank(regexprep(nxtRaw, '^\s*%\s?', '', 'once'));
        end
    end

    if is_custom_heading(content, indent, nxtBody)
        cusTitle{end+1} = content;
        cusLines{end+1} = {};
        cusAfter(end+1) = seenExamples;
        curCustom = numel(cusTitle);
        continue
    end

    % Inside a code section an unindented line is no longer code (rule 4).
    if curCustom == 0 && any(strcmp(section, {'usage','examples'})) && indent == 0
        section = 'notes';
        S.notes{end+1} = content;
        continue
    end

    if curCustom > 0
        cusLines{curCustom}{end+1} = body;
        continue
    end

    switch section
        case {'description','usage','examples','notes'}
            S.(section){end+1} = body;

        case {'inputs','outputs'}
            lst = S.(section);
            if inTail.(section)
                S.([section '_tail']){end+1} = body;
            elseif ~isempty(regexp(content, ITEMPAT, 'once'))
                if itemIndent.(section) < 0, itemIndent.(section) = indent; end
                % An item indented beyond the first input or output entry is treated as a
                % sub-option rather than a separate top-level item.
                if indent > itemIndent.(section) && ~isempty(lst)
                    lst{end+1} = [NST content];
                else
                    lst{end+1} = content;
                end
            elseif wasBlank && endsWith(content, ':') ...
                    && isempty(regexp(content, '\s-\s', 'once'))
                % Treat a line ending in a colon as a group label only when followed by
                % actual items; otherwise, treat it as the start of a prose paragraph.
               if ~isempty(regexp(next_content(lines, i), ITEMPAT, 'once'))
                    lst{end+1} = [LBL regexprep(content, ':$', '')];
                else
                    inTail.(section) = true;
                    S.([section '_tail']){end+1} = body;
                end
            elseif wasBlank && ~isempty(lst) && indent <= max(itemIndent.(section), 0)
                inTail.(section) = true;
                S.([section '_tail']){end+1} = body;
            elseif isempty(lst)
                lst{end+1} = content;
            else
                lst{end} = [lst{end} ' ' content];
            end
            S.(section) = lst;

        case 'references'
            if isempty(S.references)
                S.references{1} = content;
            elseif ~isempty(regexp(content, '^[A-Z][A-Za-z''\-]+[,&]', 'once'))
                S.references{end+1} = content;
            else
                S.references{end} = [S.references{end} ' ' content];
            end

        case 'seealso'
            % Anything that is not a plain name list ends the header:
            % fmri_fisherz2p closes with a commented-out line of code and no
            % blank line before it.
            if isempty(regexp(content, '^[A-Za-z0-9_., ]+$', 'once'))
                break
            end
            S.seealso{end+1} = content;
    end
end

%% ---- render --------------------------------------------------------------
out = {};
out{end+1} = funcName;
out{end+1} = repmat('=', 1, max(numel(funcName), 3));
out{end+1} = '';

desc = S.description;
if ~isempty(desc)
    lead = regexprep(strtrim(desc{1}), ['^' upper(funcName) '\s+'], '', 'ignorecase');
    out{end+1} = rst_escape(lead);
    out{end+1} = '';
    desc(1) = [];
end

out = write_prose(out, 'Description', desc, FIELDPAT);
out = write_code (out, 'Usage',       S.usage);
out = write_defs (out, 'Inputs',      S.inputs,  NAMEPAT, LBL, NST);
out = write_prose(out, '',            S.inputs_tail,  FIELDPAT);
out = write_defs (out, 'Outputs',     S.outputs, NAMEPAT, LBL, NST);
out = write_prose(out, '',            S.outputs_tail, FIELDPAT);
for k = 1:numel(cusTitle)
    if ~cusAfter(k)
        out = write_prose(out, cusTitle{k}, cusLines{k}, FIELDPAT);
    end
end
out = write_code(out, 'Examples', S.examples);
for k = 1:numel(cusTitle)
    if cusAfter(k)
        out = write_prose(out, cusTitle{k}, cusLines{k}, FIELDPAT);
    end
end
out = write_prose(out, 'Notes', S.notes, FIELDPAT);

if ~isempty(S.references)
    out{end+1} = 'References';
    out{end+1} = '----------';
    out{end+1} = '';
    for k = 1:numel(S.references)
        out{end+1} = ['- ' rst_escape(S.references{k})];
    end
    out{end+1} = '';
end

if ~isempty(S.seealso)
    parts = strtrim(strsplit(strjoin(S.seealso, ', '), ','));
    parts = parts(~cellfun(@isempty, parts));
    if ~isempty(parts)
        out{end+1} = 'See Also';
        out{end+1} = '--------';
        out{end+1} = '';
        items = cell(1, numel(parts));
        for k = 1:numel(parts)
            nm = regexprep(parts{k}, '\.m$', '');
            if isKey(targets, nm)
                items{k} = sprintf(':doc:`%s <%s>`', nm, targets(nm));
            else
                items{k} = sprintf('``%s``', nm);
                if ~any(strcmp(nm, knownNames))
                    warning('generate_rst:danglingSeeAlso', ...
                        ['%s: "See also" names %s, which exists nowhere in ' ...
                         'the toolbox. Fix or remove the reference.'], funcName, nm);
                end
            end
        end
        out{end+1} = strjoin(items, ' · ');
        out{end+1} = '';
    end
end

rstFile = fullfile(rstFolder, [funcName '.rst']);
fid = fopen(rstFile, 'w');
if fid == -1
    error('generate_rst:cannotWrite', 'Could not write RST file: %s', rstFile);
end
for k = 1:numel(out)
    fprintf(fid, '%s\n', out{k});
end
fclose(fid);
end

%% ---- helpers -------------------------------------------------------------
function tf = is_custom_heading(content, indent, nextBody)
% An ALL-CAPS run-in heading the help text invents for itself.
%
% Identify headings conservatively: they must be unindented, short, begin
% with an all-caps word, lack trailing punctuation, and be followed by a
% blank or indented line. This avoids treating acronym-led prose as a heading.
tf = false;
if indent ~= 0 || isempty(content) || numel(content) > 80, return, end
if any(content(end) == '.,;:'), return, end
first = regexp(content, '^\S+', 'match', 'once');
if isempty(regexp(first, '^[A-Z][A-Z0-9_]+$', 'once')), return, end
nxt = strtrim(nextBody);
tf = isempty(nxt) || (numel(nextBody) - numel(regexprep(nextBody,'^\s*','','once'))) > 0;
end

function c = next_content(lines, i)
% The next non-blank comment line after i, stripped. '' if there is none.
c = '';
for k = i+1:numel(lines)
    s = strtrim(lines{k});
    if ~startsWith(s, '%'), return, end
    t = strtrim(regexprep(lines{k}, '^\s*%\s?', '', 'once'));
    if ~isempty(t), c = t; return, end
end
end

function s = rst_escape(s)
% Escape RST inline-markup characters in prose. Use STRREP where possible so
% the text is handled literally rather than interpreted as a regular expression.
s = strrep(s, '\', '\\');
s = strrep(s, '*', '\*');
s = strrep(s, '`', '\`');
s = strrep(s, '|', '\|');
% An underscore ends a reference in RST whenever it is not followed by an
% alphanumeric, not only at end of line. Internal ones (fmri_vol2vect) are
% left alone.
s = regexprep(s, '_(?![A-Za-z0-9])', '\\_');
end

function items = trim_blanks(items)
while ~isempty(items) && isempty(strtrim(items{1})), items(1)   = []; end
while ~isempty(items) && isempty(strtrim(items{end})), items(end) = []; end
end

function n = indent_of(s)
n = numel(s) - numel(regexprep(s, '^\s*', '', 'once'));
end

function tf = looks_like_code(s)
tf = ~isempty(regexp(s, '[=;{}]|\w\(', 'once')) || ...
     ~isempty(regexp(s, '^\s*\[', 'once'));
end

function [groups, isCode] = classify_run(run)
% Split an indented run into groups by indent level, each flagged code or not.
%
% Classify indented content by indentation level so prose and code remain
% separate without splitting multi-line diagrams. A short unpunctuated line
% immediately before code is treated as the diagram heading.
g = {}; gi = [];
for k = 1:numel(run)
    ind = indent_of(run{k});
    if ~isempty(g) && gi(end) == ind
        g{end}{end+1} = run{k};
    else
        g{end+1} = run(k);  gi(end+1) = ind;
    end
end
code = false(1, numel(g));
for k = 1:numel(g)
    for j = 1:numel(g{k})
        if looks_like_code(strtrim(g{k}{j})), code(k) = true; break, end
    end
end
groups = {}; isCode = [];
k = 1;
while k <= numel(g)
    merge = false;
    if ~code(k) && numel(g{k}) == 1 && k < numel(g) && code(k+1)
        t = strtrim(g{k}{1});
        if ~any(t(end) == '.:;'), merge = true; end
    end
    if merge
        groups{end+1} = [g{k} g{k+1}];  isCode(end+1) = true;  k = k + 2;
    else
        groups{end+1} = g{k};  isCode(end+1) = code(k);  k = k + 1;
    end
end
end

function out = emit_block(out, lines, isCode)
if isCode
    out{end+1} = '.. code-block:: matlab';
    out{end+1} = '';
    strip = inf;
    for k = 1:numel(lines)
        if ~isempty(strtrim(lines{k})), strip = min(strip, indent_of(lines{k})); end
    end
    if ~isfinite(strip), strip = 0; end
    for k = 1:numel(lines)
        if isempty(strtrim(lines{k}))
            out{end+1} = '';
        else
            out{end+1} = deblank(['   ' lines{k}(strip+1:end)]);
        end
    end
else
    txt = cell(1, numel(lines));
    for k = 1:numel(lines), txt{k} = strtrim(lines{k}); end
    out{end+1} = rst_escape(strjoin(txt, ' '));
end
out{end+1} = '';
end

function out = write_prose(out, head, items, FIELDPAT)
% Flowing paragraphs. Runs of indented code and of 'Name : value' field lines
% keep their own shape instead of being folded into the paragraph, and
% nothing becomes a bullet unless the source wrote one.
items = trim_blanks(items);
if isempty(items), return, end
if ~isempty(head)
    out{end+1} = head;
    out{end+1} = repmat('-', 1, max(numel(head), 3));
    out{end+1} = '';
end

base = inf;
for k = 1:numel(items)
    if ~isempty(strtrim(items{k})), base = min(base, indent_of(items{k})); end
end
if ~isfinite(base), base = 0; end

para = {}; run = {}; field = {}; bul = {}; bulIndent = 0;
for k = 1:numel(items)
    it = items{k};
    if isempty(strtrim(it))
        [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
        continue
    end
    ind = indent_of(it);
    txt = strtrim(it);

    % Detect source bullets before applying indentation rules; otherwise, an
    % indented list containing code-like text may be misclassified as code.
    tok = regexp(txt, '^([-*+]|\(?\d{1,2}[.)])\s+(.*)$', 'tokens', 'once');
    if ~isempty(tok)
        if ~isempty(para) || ~isempty(field) || ~isempty(run)
            [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
        end
        bul{end+1} = tok;
        bulIndent  = ind;
        continue
    end
    if ~isempty(bul) && ind > bulIndent
        bul{end}{end+1} = txt;        % wrapped continuation of this item
        continue
    end
    if ~isempty(bul)
        [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
    end

    if ind > base
        if ~isempty(para) || ~isempty(field)
            [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
        end
        run{end+1} = it;
    elseif ~isempty(regexp(txt, FIELDPAT, 'once'))
        if ~isempty(para) || ~isempty(run)
            [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
        end
        field{end+1} = it;
    else
        if ~isempty(run) || ~isempty(field)
            [out, para, run, field, bul] = flush_prose(out, para, run, field, bul);
        end
        para{end+1} = it;
    end
end
[out, ~, ~, ~, ~] = flush_prose(out, para, run, field, bul);
while ~isempty(out) && isempty(out{end}), out(end) = []; end
out{end+1} = '';
end

function [out, para, run, field, bul] = flush_prose(out, para, run, field, bul)
DEFPAT = '^\S.{0,40}?\s+-\s+\S';
if ~isempty(para)
    txt = cell(1, numel(para));
    for k = 1:numel(para), txt{k} = strtrim(para{k}); end
    joined = strjoin(txt, ' ');
    if numel(para) == 1 && endsWith(joined, ':') && numel(joined) <= 60
        % A short line ending in a colon introduces what follows; setting it
        % bold separates fmri_makevizpar's per-viewer blocks from their lists.
        out{end+1} = ['**' rst_escape(joined) '**'];
    else
        out{end+1} = rst_escape(joined);
    end
    out{end+1} = '';
end
if ~isempty(bul)
    for k = 1:numel(bul)
        mk = bul{k}{1};
        if any(strcmp(mk, {'-','*','+'})), mk = '-'; end
        out{end+1} = [mk ' ' rst_escape(strjoin(bul{k}(2:end), ' '))];
    end
    out{end+1} = '';
end
if ~isempty(field)
    for k = 1:numel(field)
        out{end+1} = ['| ' rst_escape(strtrim(field{k}))];
    end
    out{end+1} = '';
end
if ~isempty(run)
    rbase = inf;
    for k = 1:numel(run)
        if ~isempty(strtrim(run{k})), rbase = min(rbase, indent_of(run{k})); end
    end
    if ~isfinite(rbase), rbase = 0; end
    if ~isempty(regexp(strtrim(run{1}), DEFPAT, 'once'))
        % Alignment decides where each entry starts; deeper lines continue it.
        defs = {};
        for k = 1:numel(run)
            if indent_of(run{k}) == rbase && ~isempty(regexp(run{k}, '\s-\s', 'once'))
                defs{end+1} = {strtrim(run{k})};
            elseif ~isempty(defs)
                defs{end}{end+1} = strtrim(run{k});
            end
        end
        for k = 1:numel(defs)
            s = rst_escape(strjoin(defs{k}, ' '));
            s = regexprep(s, '^(\S.{0,40}?)\s+-\s+', '**$1** -- ', 'once');
            out{end+1} = ['- ' s];
        end
        out{end+1} = '';
    else
        [groups, isCode] = classify_run(run);
        for k = 1:numel(groups)
            out = emit_block(out, groups{k}, isCode(k));
        end
    end
end
para = {}; run = {}; field = {}; bul = {};
end

function out = write_code(out, head, items)
items = trim_blanks(items);
if isempty(items), return, end
out{end+1} = head;
out{end+1} = repmat('-', 1, numel(head));
out{end+1} = '';
out{end+1} = '.. code-block:: matlab';
out{end+1} = '';
strip = inf;
for k = 1:numel(items)
    if ~isempty(strtrim(items{k})), strip = min(strip, indent_of(items{k})); end
end
if ~isfinite(strip), strip = 0; end
for k = 1:numel(items)
    if isempty(strtrim(items{k}))
        out{end+1} = '';
    else
        out{end+1} = deblank(['   ' items{k}(strip+1:end)]);
    end
end
out{end+1} = '';
end

function out = write_defs(out, head, items, NAMEPAT, LBL, NST)
if isempty(items), return, end
out{end+1} = head;
out{end+1} = repmat('-', 1, numel(head));
out{end+1} = '';
for k = 1:numel(items)
    if startsWith(items{k}, NST)
        s = rst_escape(items{k}(numel(NST)+1:end));
        s = regexprep(s, ['^(' NAMEPAT ')\s+-\s+'], '**$1** -- ');
        if ~isempty(out) && ~startsWith(out{end}, '  - ')
            out{end+1} = '';
        end
        out{end+1} = ['  - ' s];
        continue
    end
    if ~isempty(out) && startsWith(out{end}, '  - ')
        out{end+1} = '';
    end
    if startsWith(items{k}, LBL)
        out{end+1} = '';
        out{end+1} = ['*' rst_escape(items{k}(numel(LBL)+1:end)) '*'];
        out{end+1} = '';
        continue
    end
    item = rst_escape(items{k});
    item = regexprep(item, ['^(' NAMEPAT ')\s+-\s+'], '**$1** -- ');
    out{end+1} = ['- ' item];
end
out{end+1} = '';
end