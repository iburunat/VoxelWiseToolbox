function legend_img = fmri_createlegend(labels, colors, varargin)
% FMRI_CREATELEGEND  Create a legend as an image for export.
%
% Usage:
%   legend_img = fmri_createlegend(labels, colors)
%   legend_img = fmri_createlegend(labels, colors, 'Title', 'Regions')
%   legend_img = fmri_createlegend(labels, colors, 'FontSize', 12, 'MaxLabelLength', 25)
%
% Inputs:
%   LABELS - Legend entries, cell array of char (K x 1). Entries longer than
%            MAXLABELLENGTH are truncated with an ellipsis.
%   COLORS - RGB colour per entry (K x 3), values in [0, 1]. Row k is the
%            swatch drawn beside LABELS{k}; pass the same matrix used for the
%            rendering, so that key and figure agree.
%
%   Name-value pairs:
%   'Title'           - Heading above the legend. Default: '' (none).
%   'FontSize'        - Label font size in points. Default: 10.
%   'MaxLabelLength'  - Characters before a label is truncated. Default: 25.
%   'ColorSwatchSize' - Swatch half-height in axis units. Default: 0.3.
%   'FigureSize'      - [width height] in pixels. Default: sized automatically
%                       from the number and length of the labels. Passing a
%                       value overrides that.
%   'Padding'         - Margin around the legend in pixels. Default: 10.
%   'Axes'            - Existing axes to draw into. Default: [], which opens
%                       a figure and returns the legend as an image. When
%                       given, the legend is drawn in that axes, no figure
%                       is opened, and LEGEND_IMG is returned empty. This is
%                       how the viewers place a key beside a label map.
%
% Outputs:
%   LEGEND_IMG - RGB image matrix that can be saved with imwrite(). Empty when
%                LABELS is empty.
%
% Note:
%   A figure window is opened to display the result. When generating legends
%   in a loop, close it as you go.
%
% Examples:
%   % Save as PNG
%   img = fmri_createlegend(list{2}, colors, 'Title', 'Regions');
%   imwrite(img, 'legend.png');
%
%   % Display in a figure
%   figure; imshow(img);
%
% See also: fmri_distinctcolors, fmri_show3dba, fmri_show3datlas,
%           fmri_showslices_int, fmri_colorbar

% Parse inputs
p = inputParser;
p.addRequired('labels', @iscell);
p.addRequired('colors', @(x) isnumeric(x) && size(x,2)==3);
p.addParameter('Title', '', @ischar);
p.addParameter('MaxLabelLength', 25, @isscalar);
p.addParameter('FontSize', 10, @isscalar);
p.addParameter('ColorSwatchSize', 0.3, @isscalar);
p.addParameter('FigureSize', [], @(x) isempty(x) || numel(x) == 2);
p.addParameter('Padding', 10, @isscalar);  % Padding around legend in pixels
p.addParameter('Axes', [], @(x) isempty(x) || isgraphics(x, 'axes'));
p.parse(labels, colors, varargin{:});

labels = p.Results.labels;
colors = p.Results.colors;
titleStr = p.Results.Title;
maxLabelLength = p.Results.MaxLabelLength;
fs = p.Results.FontSize;
swatchSize = p.Results.ColorSwatchSize;
figSize = p.Results.FigureSize;
padding = p.Results.Padding;
targetAx = p.Results.Axes;

n = numel(labels);
if n == 0
    legend_img = [];
    return;
end

% ---- CALCULATE LEGEND DIMENSIONS ----
% Determine layout
longest = max(cellfun(@length, labels));
if longest > 30
    perCol = 12;
elseif longest > 20
    perCol = 15;
else
    perCol = 20;
end

nCol = ceil(n / perCol);
nRow = min(n, perCol);

% Estimate character width in pixels (roughly font_size * 0.6)
charWidth = fs * 0.6;
effectiveLen = min(longest, maxLabelLength);
if longest > maxLabelLength
    effectiveLen = maxLabelLength - 3;   % room for the ellipsis
end

% Calculate needed width: swatch + gap + text
swatchWidthPx = 20;  % Fixed swatch width in pixels
gapPx = 10;
textWidthPx = effectiveLen * charWidth;
totalWidthPx = swatchWidthPx + gapPx + textWidthPx + padding * 2;
totalHeightPx = nRow * (fs * 1.5) + padding * 2;

% Tight horizontal margin: the computed width already accounts for the
% swatch, gap and text, so this is just breathing room.
figWidth = max(totalWidthPx + 20, 300);

% Add extra height for title if present
if ~isempty(titleStr)
    titleExtraHeight = fs * 2.5;  % Extra height for title
else
    titleExtraHeight = 0;
end
figHeight = max(totalHeightPx + 30 + titleExtraHeight, 300);

% FIGURESIZE was parsed and then ignored; the computed size always won, so
% passing it had no effect. Honour it when given, keep auto-sizing otherwise.
if ~isempty(figSize)
    figWidth = figSize(1);  figHeight = figSize(2);
end

% Calculate padding for legend position (tighter)
xPad = 15 / figWidth;  % Small padding on sides
% Different padding for top and bottom
if ~isempty(titleStr)
    yPadBottom = 10 / figHeight;  % Bottom padding
    yPadTop = max(25, 2*fs) / figHeight;   % room for the title at any font size
else
    yPadBottom = 10 / figHeight;
    yPadTop = 10 / figHeight;
end

% Position the legend properly
pos = [xPad, yPadBottom, 1 - 2*xPad, 1 - yPadTop - yPadBottom];

% Create hidden figure
if isempty(targetAx)
    % Standalone: draw into a hidden figure, to be captured as an image.
    fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'pixels', ...
                 'Position', [100 100 figWidth figHeight]);
    axl = axes('Position', pos);
else
    % Draw into the caller's axes: no figure of our own, nothing captured.
    fig = [];
    axl = targetAx;
    cla(axl);
end

% Create axes that fill the figure
% ax = axes('Position', [0 0 1 1]);
% hold(ax, 'on');
% axis off;
hold(axl, 'on');

% Set up the legend axes
set(axl, 'XLim', [-0.1 nCol+0.1], 'YLim', [-0.1 nRow+0.1], ...
         'YDir', 'reverse', 'XTick', [], 'YTick', [], ...
         'Color', 'w', 'XColor', 'none', 'YColor', 'none', ...
         'Box', 'off');

% Fixed positions for consistency
swatchX = 0.02;

% Square swatches: convert the swatch height, which is set in y data units,
% into the x data units that give the same number of pixels. Without this the
% swatch shape follows the axes aspect ratio and stretches in a tall panel.
oldunits = get(axl, 'Units');
set(axl, 'Units', 'pixels');
axpx = get(axl, 'Position');
set(axl, 'Units', oldunits);
swatchWidth = (2*swatchSize) * (axpx(4)/(nRow+0.2)) * ((nCol+0.2)/axpx(3));
swatchWidth = min(swatchWidth, 0.45);        % never crowd out the label

textX = swatchX + swatchWidth + 0.04;

for k = 1:n
    col = floor((k-1) / perCol);
    row = mod(k-1, perCol) + 0.5;
    
    label = labels{k};
    
    % Truncate long labels
    if length(label) > maxLabelLength
        label = [label(1:maxLabelLength-3) '...'];
    end
    
    % Colour swatch
    patch(axl, col + [swatchX swatchX+swatchWidth swatchX+swatchWidth swatchX], ...
          row + [-swatchSize -swatchSize swatchSize swatchSize], ...
          colors(k,:), 'EdgeColor', 'none');
    
    % Label text
    text(axl, col + textX, row, label, ...
         'FontSize', fs, 'VerticalAlignment', 'middle', 'Color', 'k', ...
         'Interpreter', 'none');
end

% Add title if provided
if ~isempty(titleStr)
    % Create title with offset
    t = title(axl, titleStr, 'FontSize', fs + 1, 'Color', 'k');
    % Move title up slightly (in normalized units)
    set(t, 'Units', 'normalized');
    pos_title = get(t, 'Position');
    pos_title(2) = pos_title(2) + 0.02;  % Move up slightly
    set(t, 'Position', pos_title);
end


hold(axl, 'off');

if isempty(fig)
    legend_img = [];     % drawn in place: nothing to capture, nothing to show
    return
end

drawnow;
frame      = getframe(fig);
legend_img = frame.cdata;
close(fig);

figure('Name', 'Legend', 'NumberTitle', 'off');
image(legend_img); axis image off
end