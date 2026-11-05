function generate_rst(mFile, rstFolder, targets, knownNames)
%GENERATE_RST  Create a Sphinx RST page from a MATLAB help header.
%
% Usage:
%   generate_rst(mFile, rstFolder)
%   generate_rst(mFile, rstFolder, allNames)
%   generate_rst(mFile, rstFolder, allNames, linkPrefix)
%
% Inputs:
%   MFILE     - Full path to the .m file.
%   RSTFOLDER - Folder the .rst file is written to (created if absent).
%   ALLNAMES  - Optional cellstr of every documented function name. When
%               given, "See also" entries that appear in it become :doc:
%               cross-references; entries that do not are left as plain
%               literal text AND reported, which catches help headers that
%               point at functions that no longer exist.
%   LINKPREFIX- Optional path prefix for those cross-references, default ''.
%               Sphinx resolves a relative :doc: target against the folder
%               the PAGE lives in, not against the source root. A function
%               page in modules/ links a sibling as `fmri_x`, but a demo
%               page in demos/ must link it as `../modules/fmri_x` or the
%               build fails with "unknown document". Pass '../modules/'
%               when writing demo pages.
%
% Notes:
%   Differences from the first version, each fixing an observed failure:
%
%   1. SCRIPTS ARE HANDLED. The old version required line 1 to start with
%      'function' and silently produced an EMPTY page for anything else, so
%      every demo script documented as nothing at all. The help block is now
%      taken as the first run of comment lines, whether or not a function
%      line precedes it.
%
%   2. RST SPECIAL CHARACTERS ARE ESCAPED. Help text contains * and ` and |
%      (e.g. "N*(N-1)/2" in fmri_rsa, "fSNR * (delta-St / St)" in fmri_cnr).
%      Unescaped, Sphinx reads these as emphasis or substitution markup and
%      either mangles the line or emits a warning. Escaping is applied to
%      prose only, never inside code blocks, where the text must stay literal.
%
%   3. CODE INDENTATION SURVIVES. The old version strtrim'ed every line
%      before writing it into the code block, flattening nested examples.
%      Detection still uses the trimmed text; the block keeps the original.
%
%   4. MORE SECTIONS RECOGNISED. 'Optional', 'Description' and 'Note' were
%      not detected, so their contents were silently appended to whatever
%      section came before - usually Inputs.
%
%   5. NO '.. currentmodule::'. That is a Python-domain directive and means
%      nothing in a MATLAB project.
%
% See also: batch_generate

if nargin < 3, targets = containers.Map('KeyType','char','ValueType','char'); end
if nargin < 4, knownNames = {}; end

% One or more ALLCAPS-ish names, optionally comma separated, then ' - '.
% The first version's class had no space in it, so a header line like
% 'TS1, TS2  - Time series vectors' was not recognised as a new item and
% never got its name bolded.
NAMEPAT = '[A-Za-z0-9_\[\]()]+(?:\s*,\s*[A-Za-z0-9_\[\]()]+)*';
if ~isfolder(rstFolder), mkdir(rstFolder); end

[~, funcName] = fileparts(mFile);

fid = fopen(mFile, 'r');
if fid == -1
    error('generate_rst:cannotRead', 'Could not open file: %s', mFile);
end
lines = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
lines = lines{1};

[description, usage, inputs, outputs, examples, notes, references, seealso] = ...
    deal({}, {}, {}, {}, {}, {}, {}, {});

section    = 'description';
inDocBlock = false;
started    = false;

for i = 1:numel(lines)
    raw  = lines{i};
    line = strtrim(raw);

    % The help block is the FIRST run of comment lines. A leading 'function'
    % line is skipped; a script with no function line is handled too.
    if ~inDocBlock
        if startsWith(line, 'function')
            inDocBlock = true;    continue
        elseif startsWith(line, '%')
            inDocBlock = true;    % script: the block starts right here
        elseif isempty(line)
            continue              % blank lines before the block
        else
            break                 % code before any help: nothing to document
        end
    end

    if ~startsWith(line, '%')
        if started, break, else, continue, end
    end
    started = true;

    % Strip the leading '%' and at most one following space, KEEPING any
    % further indentation so code blocks retain their shape.
    body    = regexprep(raw, '^\s*%\s?', '', 'once');
    content = strtrim(body);
    if isempty(content)
        % A bare '%' is a paragraph break in the help text. Dropping it ran
        % separate paragraphs together and glued displayed formulae onto the
        % prose above them. Record it, but never as the first line of a block.
        switch section
            case 'description', if ~isempty(description), description{end+1} = ''; end
            case 'notes',       if ~isempty(notes),       notes{end+1}       = ''; end
            case 'usage',       if ~isempty(usage),       usage{end+1}       = ''; end
            case 'examples',    if ~isempty(examples),    examples{end+1}    = ''; end
        end
        continue
    end

    % '% ----' rules and '% ====' banners are layout, not content.
    if ~isempty(regexp(content, '^[-=#*_]{3,}$', 'once')), continue, end

    low = lower(content);
    hit = false;
    heads = { 'usage:',       'usage'
              'inputs:',      'inputs'
              'input:',       'inputs'
              'optional',     'inputs'      % 'Optional (name-value pairs):'
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
    for h = 1:size(heads,1)
        if startsWith(low, heads{h,1})
            section = heads{h,2};
            rest = strtrim(content(numel(heads{h,1})+1:end));
            % 'Optional (name-value pairs):' - drop the trailing colon part
            rest = regexprep(rest, '^\([^)]*\):?\s*', '');
            if ~isempty(rest)
                switch section
                    case 'usage',       usage{end+1}      = rest; %#ok<*AGROW>
                    case 'inputs',      inputs{end+1}     = rest;
                    case 'outputs',     outputs{end+1}    = rest;
                    case 'examples',    examples{end+1}   = rest;
                    case 'description', description{end+1}= rest;
                    case 'notes',       notes{end+1}      = rest;
                    case 'references',  references{end+1} = rest;
                    case 'seealso',     seealso{end+1}    = rest;
                end
            end
            hit = true; break
        end
    end
    if hit, continue, end

    switch section
        case 'description'
            description{end+1} = content;

        case {'usage','examples'}
            % Keep the raw (indented) body for code blocks.
            if strcmp(section,'usage'), usage{end+1} = body;
            else,                       examples{end+1} = body; end

        case {'inputs','outputs'}
            isNewItem = ~isempty(regexp(content, ['^' NAMEPAT '\s+-\s'], 'once'));
            lst = inputs; if strcmp(section,'outputs'), lst = outputs; end
            if isNewItem || isempty(lst)
                lst{end+1} = content;
            else
                lst{end} = [lst{end} ' ' content];
            end
            if strcmp(section,'outputs'), outputs = lst; else, inputs = lst; end

        case 'notes'
            notes{end+1} = content;

        case 'references'
            % A new citation starts with "Surname, " or "Surname & "
            if isempty(references)
                references{1} = content;
            elseif ~isempty(regexp(content, '^[A-Z][A-Za-z''\-]+[,&]', 'once'))
                references{end+1} = content;
            else
                references{end} = [references{end} ' ' content];
            end

        case 'seealso'
            % "See also" is the last section by convention, and the lines
            % after it are a comma-separated list of names. fmri_fisherz2p
            % ends its header with a commented-out line of code and NO blank
            % line between, so '%p = 2 * (1 - normcdf(abs(z)));' was being
            % collected as a "See also" entry. Anything that is not a plain
            % name list ends the header.
            if isempty(regexp(content, '^[A-Za-z0-9_., ]+$', 'once'))
                break
            end
            seealso{end+1} = content;
    end
end

%% ---- write ---------------------------------------------------------------
rstFile = fullfile(rstFolder, [funcName '.rst']);
fid = fopen(rstFile, 'w');
if fid == -1
    error('generate_rst:cannotWrite', 'Could not write RST file: %s', rstFile);
end

% The title rule must be at least as long as the title, or Sphinx warns.
fprintf(fid, '%s\n', funcName);
fprintf(fid, '%s\n\n', repmat('=', 1, max(numel(funcName), 3)));

% The first help line is "FMRI_X  One-line summary." Lift it out as the lead
% paragraph and drop the repeated function name from it.
if ~isempty(description)
    lead = regexprep(description{1}, ['^' upper(funcName) '\s+'], '', 'ignorecase');
    fprintf(fid, '%s\n\n', rst_escape(lead));
    description(1) = [];
end

write_prose(fid, 'Description', description);
write_code (fid, 'Usage',       usage);
write_defs (fid, 'Inputs',      inputs);
write_defs (fid, 'Outputs',     outputs);
write_code (fid, 'Examples',    examples);
write_prose(fid, 'Notes',       notes, true);
write_prose(fid, 'References',  references, true);

% See also -> :doc: links, with unresolved names reported rather than linked.
if ~isempty(seealso)
    parts = strtrim(strsplit(strjoin(seealso, ', '), ','));
    parts = parts(~cellfun(@isempty, parts));
    if ~isempty(parts)
        fprintf(fid, 'See Also\n--------\n\n');
        out = cell(1, numel(parts));
        for i = 1:numel(parts)
            nm = regexprep(parts{i}, '\.m$', '');
            if isKey(targets, nm)
                out{i} = sprintf(':doc:`%s <%s>`', nm, targets(nm));
            elseif any(strcmp(nm, knownNames))
                % Exists somewhere in the toolbox but has no page of its own:
                % a private helper, a setup or utility script, a test. A
                % perfectly good thing to mention, just not linkable. Render
                % it as literal text and say nothing - warning here buried the
                % one reference that was actually broken among four that were
                % not.
                out{i} = sprintf('``%s``', nm);
            else
                out{i} = sprintf('``%s``', nm);
                warning('generate_rst:danglingSeeAlso', ...
                        ['%s: "See also" names %s, which exists nowhere in ' ...
                         'the toolbox. Fix or remove the reference.'], ...
                        funcName, nm);
            end
        end
        fprintf(fid, '%s\n\n', strjoin(out, ' · '));
    end
end

fclose(fid);
end

%% ---- helpers -------------------------------------------------------------
function s = rst_escape(s)
% Escape the inline-markup characters that occur in these help headers.
% strrep is used rather than regexprep so nothing in the text is treated as
% a pattern or as a replacement escape.
s = strrep(s, '\', '\\');
s = strrep(s, '*', '\*');
s = strrep(s, '`', '\`');
s = strrep(s, '|', '\|');
% An underscore ENDS a reference in RST whenever it is not followed by an
% alphanumeric character - not only at end of line. 'rp_*.txt' in
% fmri_correctmovement's notes therefore read as a reference to a target
% named "rp" and failed the build with "Unknown target name". Internal
% underscores (fmri_vol2vect) are still left alone.
s = regexprep(s, '_(?![A-Za-z0-9])', '\\_');
end

function write_prose(fid, head, items, asList)
if nargin < 4, asList = false; end
if isempty(items), return, end
fprintf(fid, '%s\n%s\n\n', head, repmat('-', 1, numel(head)));
for i = 1:numel(items)
    if asList
        fprintf(fid, '- %s\n', rst_escape(items{i}));
    else
        fprintf(fid, '%s\n', rst_escape(items{i}));
    end
end
fprintf(fid, '\n');
end

function write_code(fid, head, items)
if isempty(items), return, end
fprintf(fid, '%s\n%s\n\n', head, repmat('-', 1, numel(head)));
fprintf(fid, '.. code-block:: matlab\n\n');
for i = 1:numel(items)
    fprintf(fid, '   %s\n', items{i});   % literal: no escaping
end
fprintf(fid, '\n');
end

function write_defs(fid, head, items)
if isempty(items), return, end
NAMEPAT = '[A-Za-z0-9_\[\]()]+(?:\s*,\s*[A-Za-z0-9_\[\]()]+)*';
fprintf(fid, '%s\n%s\n\n', head, repmat('-', 1, numel(head)));
for i = 1:numel(items)
    item = rst_escape(items{i});
    item = regexprep(item, ['^(' NAMEPAT ')\s+-\s+'], '**$1** -- ');
    fprintf(fid, '- %s\n', item);
end
fprintf(fid, '\n');
end
