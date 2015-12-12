mochikitFunctions = [
  # Async
  "callLater(","doXHR(","doSimpleXMLHttpRequest(","evalJSONRequest(","fail(","gatherResults(",
  "getXMLHttpRequest(","maybeDeferred(","loadJSONDoc(","loadScript(","sendXMLHttpRequest(","succeed(",
  "wait("

  # Base
  "arrayEqual(","average(","bind(","bindLate(","bindMethods(","bool(","camelize(","clone(",
  "compare(","compose(","concat(","counter(","extend(","evalJSON(","filter(","findValue(",
  "findIdentical(","flattenArguments(","flattenArray(","forwardCall(","isArrayLike(","isCallable(",
  "isDateLike(","isEmpty(","isNotEmpty(","isNull(","isUndefined(","isUndefinedOrNull(","isValue(",
  "itemgetter(","items(","keyComparator(","keys(","listMax(","listMin(","listMinMax(","map(",
  "mean(","median(","merge(","method(","methodcaller(","module(","moduleExport(","nameFunctions(",
  "noop(","objEqual(","nodeWalk(","objMax(","objMin(","parseQueryString(","partial(","queryString(",
  "registerComparator(","registerJSON(","registerRepr(","repr(","reverseKeyComparator(",
  "serializeJSON(","setdefault(","typeMatcher(","update(","updatetree(","urlEncode(","values(",
  "xfilter(","xmap(","zip("

  # DOM
  "addElementClass(","addLoadEvent(","addToCallStack(","appendChildNodes(",
  "insertSiblingNodesBefore(","insertSiblingNodesAfter(","createDOM(","createDOMFunc(",
  "currentDocument(","currentWindow(","emitHTML(","escapeHTML(","focusOnLoad(","formContents(",
  "getElement(","getElementsByTagAndClassName(","getFirstElementByTagAndClassName(",
  "getFirstParentByTagAndClassName(","getNodeAttribute(","hasElementClass(","isChildNode(",
  "registerDOMConverter(","removeElement(","removeElementClass(","removeEmptyTextNodes(",
  "replaceChildNodes(","scrapeText(","setElementClass(","setNodeAttribute(","swapDOM(",
  "swapElementClass(","toggleElementClass(","toHTML(","updateNodeAttributes(","withWindow(",
  "withDocument(","computedStyle(","elementDimensions(","elementPosition(","getViewportDimensions(",
  "hideElement(","makeClipping(","makePositioned(","setElementDimensions(","setElementPosition(",
  "setDisplayForElement(","setOpacity(","showElement(","undoClipping(","undoPositioned(",
  "Coordinates(","Dimensions("

  # DragDrop
  "Draggable(","Droppable("

  # Color
  "Color(","clampColorComponent(","hslToRGB(","hsvToRGB(","toColorPart(","rgbToHSL(","rgbToHSV("

  # DateTime
  "isoDate(","isoTimestamp(","toISOTime(","toISOTimestamp(","toISODate(","americanDate(",
  "toPaddedAmericanDate(","toAmericanDate("

  # Format
  "formatLocale(","lstrip(","numberFormatter(","percentFormat(","roundToFixed(","rstrip(","strip(",
  "truncToFixed(","twoDigitAverage(","twoDigitFloat("

  # Iter
  "applymap(","chain(","cycle(","dropwhile(","every(","exhaust(","forEach(","groupby(",
  "groupby_as_array(","iextend(","ifilter(","ifilterfalse(","imap(","islice(","iter(","izip(",
  "next(","range(","reduce(","registerIteratorFactory(","repeat(","reversed(","some(",
  "sorted(","sum(","takewhile(","tee("

  # Logging
  "LogMessage(","Logger(","alertListener(","log(","logDebug(","logError(","logFatal(",
  "logLevelAtLeast(","logWarning("

  # LoggingPane
  "LoggingPane(","createLoggingPane("

  # Selector
  "findDocElements(","findChildElements(","Selector("

  # Signal
  "connect(","connectOnce(","disconnect(","disconnectAll(","disconnectAllTo(","signal(","event(",
  "src(","type(","target(","modifier(","stopPropagation(","preventDefault(","stop(","key(","mouse(",
  "relatedTarget(","confirmUnload("

  # Style
  "getStyle(","setStyle(","setOpacity(","getElementDimensions(","setElementDimensions(",
  "getElementPosition(","setElementPosition(","makePositioned(","undoPositioned(","makeClipping(",
  "undoClipping(","setDisplayForElement(","showElement(","hideElement(","getViewportDimensions(",
  "getViewportPosition(","Coordinates(","Dimensions("

  # Sortable
  "Sortable."

  # Text
  "contains(","endsWith(","format(","formatter(","formatValue(","padLeft(","padRight(","split(",
  "rsplit(","startsWith(","truncate("

  # Visual
  "roundClass(","roundElement(","toggle(","tagifyText(","multiple(","fade(","appear(","puff(",
  "blindUp(","blindDown(","switchOff(","dropOut(","shake(","slideDown(","slideUp(","squish(",
  "grow(","shrink(","pulsate(","fold(","Base(","Parallel(","Sequence(","Opacity(","Move(","Scale(",
  "Highlight(","ScrollTo(","Morph("
]

mochikitRegexes = mochikitFunctions.map (fn) ->
  new RegExp('[^\\.>\\$_]\\b' + fn.replace(/([\.\(])/, '\\$1'))

phpFileWithScriptTag = (name, lines) ->
  isPhpFile = /\.php$/.test(name)
  isPhpFile && lines.filter((line) -> /<script|js =/.test(line)).length > 0

module.exports = (stats, contents) ->
  lines = contents.split(/\n|\r\n/)

  if !/\.js$/.test(stats.name)
    return unless phpFileWithScriptTag(stats.name, lines)

  results = []
  for line, i in lines
    for regex, i in mochikitRegexes
      if regex.test(line)
        results.push(line: i, level: 'error', message: "Usage of function #{mochikitFunctions[i]})")

  results
