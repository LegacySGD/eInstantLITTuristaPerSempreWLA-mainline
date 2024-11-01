<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					var debugFeed = [];
					var debugFlag = false;
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, prizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var scenarioWinningNumbers = (scenario.split('|')[0]).split(',');
						var scenarioBonusNumber = scenario.split('|')[1];
						var scenarioYourNumbers = getYourNumbers(scenario);
						var scenarioBonusGamePrizes = (scenario.split('|')[3]).split(',');
						var convertedPrizeValues = (prizeValues.substring(1)).split('|').map(function(item) {return item.replace(/\t|\r|\n/gm, "")} );
						var prizeNames = (prizeNamesDesc.substring(1)).split(','); 

						const gridCols 		= 5;
						const gridRows 		= 3;

						var winType = [0,0,0];
						var r = [];

						///////////////////////
						// Output Game Parts //
						///////////////////////
						const cellHeight    = 48;
						const cellMargin    = 1;
						const cellSizeX     = 80;
						const cellSizeX2    = 120;
						const cellSizeY     = 48;
						const cellTextX     = 40; 
						const cellTextY     = 15; 
						const cellTextYWins = 24; 
						const cellTextY1    = 20; 
						const cellTextY2    = 40; 
						const colourBlack   = '#000000';
						const colourLime    = '#ccff99';
						const colourRed     = '#ff9999';
						const colourWhite   = '#ffffff';

						var boxColourStr  = '';
						var textColourStr = '';
						var canvasIdStr   = '';
						var elementStr    = '';

						var gridCanvasWinsHeight = cellSizeY + 2 * cellMargin;
						var gridCanvasWinsWidth  = (gridCols+1) * cellSizeX + 2 * cellMargin;
						var gridCanvasYourHeight = gridRows * cellSizeY + 2 * cellMargin;
						var gridCanvasYourWidth  = gridCols * cellSizeX + 2 * cellMargin;

						function showWinningNums(A_strCanvasId, A_strCanvasElement, A_BoxWidth, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = A_BoxWidth + 2 * cellMargin;

							var canvasHeight = cellSizeY + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + A_BoxWidth.toString() + ', ' + cellSizeY.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (A_BoxWidth - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (A_BoxWidth / 2 + cellMargin).toString() + ', ' + (cellSizeY / 2 + cellMargin).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');

							r.push('</script>');
						}

						function showBonusNum(A_strCanvasId, A_strCanvasElement, A_strBoxColour, A_strTextColour, A_strText)
						{
							var canvasCtxStr = 'canvasContext' + A_strCanvasElement;
							var canvasWidth  = cellSizeX + 2 * cellMargin;
							var canvasHeight = cellSizeY + 2 * cellMargin;

							r.push('<canvas id="' + A_strCanvasId + '" width="' + canvasWidth.toString() + '" height="' + canvasHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.font = "bold 14px Arial";');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							r.push(canvasCtxStr + '.strokeRect(' + (cellMargin + 0.5).toString() + ', ' + (cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strBoxColour + '";');
							r.push(canvasCtxStr + '.fillRect(' + (cellMargin + 1.5).toString() + ', ' + (cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + A_strTextColour + '";');
							r.push(canvasCtxStr + '.fillText("' + A_strText + '", ' + (cellSizeX / 2 + cellMargin).toString() + ', ' + (cellSizeY / 2 + cellMargin).toString() + ');');
							r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');

							r.push('</script>');
						}

						function showYourNums(A_strCanvasId, A_strCanvasElement, A_arrGrid)
						{
							var canvasCtxStr  = 'canvasContext' + A_strCanvasElement;
							var cellX         = 0;
							var cellY         = 0;
							var prizeCell     = '';
							var prizeStr	  = '';
							var symbCell      = '';
							var tempNum		  = -1;
							var boolTPCell	  = false;
							var yourCellTPCount = 0;
							var boolWinCell   = false;
							var boolBonusCell = false;
							var winAll        = false;

							for (var gridRow = 0; gridRow < gridRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < gridCols; gridCol++)
								{
									tempNum = ((gridRow)*gridCols) + gridCol;
									symbCell = A_arrGrid[tempNum][0]; 
	 								if (symbCell == 'TP')
 									{
										yourCellTPCount++;
									}
								}
							}

							r.push('<canvas id="' + A_strCanvasId + '" width="' + gridCanvasYourWidth.toString() + '" height="' + gridCanvasYourHeight.toString() + '"></canvas>');
							r.push('<script>');
							r.push('var ' + A_strCanvasElement + ' = document.getElementById("' + A_strCanvasId + '");');
							r.push('var ' + canvasCtxStr + ' = ' + A_strCanvasElement + '.getContext("2d");');
							r.push(canvasCtxStr + '.textAlign = "center";');
							r.push(canvasCtxStr + '.textBaseline = "middle";');

							for (var gridRow = 0; gridRow < gridRows; gridRow++)
							{
								for (var gridCol = 0; gridCol < gridCols; gridCol++)
								{
									boolTPCell = false;
									tempNum = ((gridRow)*gridCols) + gridCol;
									symbCell = A_arrGrid[tempNum][0]; 
									prizeCell = A_arrGrid[tempNum][1];
									prizeStr = convertedPrizeValues[getPrizeNameIndex(prizeNames, prizeCell)];

									boolBonusCell = false;
									if (symbCell == 'TP')
									{
										boolTPCell = true; // used to change font size below
										boolWinCell = (yourCellTPCount > 1);
										boolBonusCell = false; 
										symbCell = getTranslationByName("TPS1", translations);
										prizeStr = getTranslationByName("TPS2", translations);
									}
									else
									{
										boolWinCell = yourCellMatches(symbCell, scenarioWinningNumbers);
										boolBonusCell = (symbCell == scenarioBonusNumber); 
									}

									boxColourStr  = (boolBonusCell == true) ? colourRed : ((boolWinCell == true) ? colourLime : colourWhite);
									textColourStr = colourBlack; 
									cellX         = gridCol * cellSizeX;
									cellY         = gridRow * cellSizeY;

									r.push(canvasCtxStr + '.strokeRect(' + (cellX + cellMargin + 0.5).toString() + ', ' + (cellY + cellMargin + 0.5).toString() + ', ' + cellSizeX.toString() + ', ' + cellSizeY.toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + boxColourStr + '";');
									r.push(canvasCtxStr + '.fillRect(' + (cellX + cellMargin + 1.5).toString() + ', ' + (cellY + cellMargin + 1.5).toString() + ', ' + (cellSizeX - 2).toString() + ', ' + (cellSizeY - 2).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									r.push(canvasCtxStr + '.font = "bold 12px Arial";');
									r.push(canvasCtxStr + '.fillText("' + symbCell + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY1).toString() + ');');
									r.push(canvasCtxStr + '.fillStyle = "' + textColourStr + '";');
									if (boolTPCell)
									{
										r.push(canvasCtxStr + '.font = "bold 12px Arial";');
									}
									else
									{
										r.push(canvasCtxStr + '.font = "bold 10px Arial";');
									}
									if (boolBonusCell)
									{
										r.push(canvasCtxStr + '.fillText("' + prizeStr + " x10" + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
									}
									else
									{
										r.push(canvasCtxStr + '.fillText("' + prizeStr + '", ' + (cellX + cellTextX).toString() + ', ' + (cellY + cellTextY2).toString() + ');');
									}
								}
							}
							r.push('</script>');
						}

						///////////////////////
						// Main Game Symbols //
						///////////////////////
						r.push('<p>' + getTranslationByName("game1", translations) + '</p>');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						// Headings
						r.push('<tr>');
						r.push('<td colspan="4">');
						r.push(getTranslationByName("winningNumbers", translations));
						r.push('</td>');
						r.push('<td colspan="1">');
						r.push(getTranslationByName("bonusNumber", translations));
						r.push('</td>');
						r.push('</tr>');
						
						r.push('<tr>');
						for (var gridCol = 0; gridCol < scenarioWinningNumbers.length; gridCol++)
						{
							canvasIdStr = 'cvsWinningGrid0' + gridCol; 
							elementStr  = 'eleWinningGrid0' + gridCol; 

							symbCell = scenarioWinningNumbers[gridCol];
							boolWinCell = winCellMatches(symbCell, scenarioYourNumbers);

							boxColourStr  = (boolWinCell == true) ? colourLime : colourWhite;
							textColourStr = colourBlack; 
						
							r.push('<td>');
							showWinningNums(canvasIdStr, elementStr, cellSizeX, boxColourStr, textColourStr, symbCell);
							r.push('</td>');
						}

						// Bonus multiplier Number
						canvasIdStr = 'cvsBonusGrid0' + gridCols; 
						elementStr  = 'eleBonusGrid0' + gridCols; 

						symbCell = scenarioBonusNumber;
						boolWinCell = winCellMatches(symbCell, scenarioYourNumbers);

						boxColourStr  = (boolWinCell == true) ? colourRed : colourWhite;
						textColourStr = colourBlack; 
						
						r.push('<td>');
						showBonusNum(canvasIdStr, elementStr, boxColourStr, textColourStr, symbCell);
						r.push('</td>');

						r.push('</tr>');
						r.push('</table>');

						r.push('&nbsp;');

						////////////////////
						// Main Game Grid //
						////////////////////
						canvasIdStr = 'cvsYourGrid0'; 
						elementStr  = 'eleYourGrid0'; 

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						r.push('<td>' + getTranslationByName("yourNumbers", translations) + '</td>');
						r.push('</tr>');
						r.push('<tr>');
						r.push('<td align="center">');
						showYourNums(canvasIdStr, elementStr, scenarioYourNumbers);
						r.push('</td>');
						r.push('</tr>');
						r.push('</table>');

						r.push('&nbsp;');

						////////////////////
						// Game 2 Symbols //
						////////////////////
						const bonusPrizes = "ABCDEFGHIJKLM";
						var bonusPrizeCounts = bonusPrizes.split("").map(function(item) {return 0;} );
						var prizeIndex = -1;
						for (var i = 0; i < scenarioBonusGamePrizes.length; i++)
						{
							symbPrize = scenarioBonusGamePrizes[i];
							prizeIndex = bonusPrizes.indexOf(symbPrize);
							bonusPrizeCounts[prizeIndex]++;
						}

						r.push('<p>' + getTranslationByName("game2", translations) + '</p>');
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
						r.push('<tr>');
						for (var gridCol = 0; gridCol < scenarioBonusGamePrizes.length; gridCol++)
						{
							canvasIdStr = 'cvsBonusGrid0' + gridCol; 
							elementStr  = 'eleBonusGrid0' + gridCol; 

							symbPrize = scenarioBonusGamePrizes[gridCol];
							symbCell = convertedPrizeValues[getPrizeNameIndex(prizeNames, symbPrize)];
							prizeIndex = bonusPrizes.indexOf(symbPrize);
							boolWinCell = (bonusPrizeCounts[prizeIndex] > 1);

							boxColourStr  = (boolWinCell == true) ? colourLime : colourWhite;
							textColourStr = colourBlack; 
						
							r.push('<td>');
							showWinningNums(canvasIdStr, elementStr, cellSizeX2, boxColourStr, textColourStr, symbCell);
							r.push('</td>');
						}
						r.push('</tr>');
						r.push('</table>');

						r.push('&nbsp;');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						if(debugFlag)
						{
							//////////////////////////////////////
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" width="100%" class="gameDetailsTable" style="table-layout:fixed">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 							{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 								r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 								r.push('</td>');
	 							r.push('</tr>');
							}
							r.push('</table>');
						}
						return r.join('');
					}

					function getScenario(jsonContext)
					{
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					function getYourNumbers(scenario)
					{
						var outcomeData = scenario.split("|")[2];
						return outcomeData.split(",").map(function(item) {return item.split(":");} );
					}

					function winCellMatches(symbCell, A_scenarioYourNumbers)
					{
						var boolValue = false;
						for (var i = 0; i < A_scenarioYourNumbers.length; i++) // Num matches win number
 						{
							if (symbCell == A_scenarioYourNumbers[i].slice(0, 1))
							{
								boolValue = true;
							}	
						}						
						return boolValue;
					}

					function yourCellMatches(symbCell, A_scenarioWinningNumbers)
					{
						var boolValue = false;
						for (var i = 0; i < A_scenarioWinningNumbers.length; i++) // Num matches win number
 						{
							if (symbCell == A_scenarioWinningNumbers[i])
							{
								boolValue = true;
							}	
						}						
						return boolValue;
					}

					function getPrizeInCents(AA_strPrize)
					{
						return parseInt(AA_strPrize.replace(new RegExp('[^0-9]', 'g'), ''), 10);
					}

					function getCentsInCurr(AA_iPrize)
					{
						var strValue = AA_iPrize.toString();

						strValue = (strValue.length < 3) ? ('00' + strValue).substr(-3) : strValue;
						strValue = strValue.substr(0,strValue.length-2) + strDecSymb + strValue.substr(-2);
						strValue = (strValue.length > 6) ? strValue.substr(0,strValue.length-6) + strThouSymb + strValue.substr(-6) : strValue;
						strValue = (bCurrSymbAtFront) ? strCurrSymb + strValue : strValue + strCurrSymb;

						return strValue;
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(",");
						var prizeStructStrings = prizeStructures.split("|");

						for(var i = 0; i < pricePoints.length; ++i)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return "";
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					// Input: "A,B,C,D,..." and "A"
					// Output: index number
					function getPrizeNameIndex(prizeNames, currPrize)
					{
						for(var i = 0; i < prizeNames.length; ++i)
						{
							if(prizeNames[i] == currPrize)
							{
								return i;
							}
						}
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}

					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">
					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>


				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
