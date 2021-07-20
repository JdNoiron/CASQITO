// CASQITO.ijm
// 
// Computer Assisted Signal Quantification Including Threshold Options (CASQITO)
//
// Copyright 2021 Juliette de Noiron (juliette@de-noiron.fr)
// 
//This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

setTool("freehand");
path = File.openDialog("Select a File");

dir = File.getParent(path);
imageName = File.getName(path);

run("Bio-Formats Macro Extensions");
Ext.setId(path);
Ext.getSeriesCount(seriesCount);
Ext.getSizeC(channelsCount);

imageDirectory = dir + "/";
 //The next part retrieve the 4 last letters of the file's name, corresponding to the Extension, allowing the macro to use the file name in the log & quantif files title that the macro will save later
imageName = substring(imageName, 0, lastIndexOf(imageName, "."));

 //The next line is a creation of a variable equal to ".lif"
imageExt = ".lif";
 //The next line role is to recreate the the image adress including its direction, its name (without the 4 last letters) and its Extension 
imageAdress = imageDirectory + imageName + imageExt;

getDateAndTime(year, month, week, day, hour, min, sec, msec);
print("Date :  "+day+"/"+month+"/"+year);
eval("script","f =WindowManager.getFrame('Log'); f.setLocation(500,400); f.setSize(400,300);"); 
print("Time :  "+hour+":"+min+":"+sec+"");

projectName = imageName;
apeName = "Me";
c = 0;
Th = 0;
biggestThres = 0;
ExlS = 0;
l=1;

 Dialog.create("PART 1");
 	Dialog.addMessage("The file " + imageName + " contains: \n " +seriesCount + " series and use " + channelsCount + " channel(s)");
 	Dialog.addMessage("Condition name:");
 		Dialog.addString("     ", projectName); 
 	Dialog.addMessage("Experimenter :");
 		Dialog.addString("", apeName);		
 	Dialog.addMessage("How background noise should be reduced?");
 		Dialog.addChoice("", newArray("A. Median filter with a radius of 1 before Z projection", "B. Personal protocol before Z projection", "C. Personal protocol after Z projection", "D. Personal protocol before & after Z projection", "E. No background noise treatment"));
 	Dialog.addMessage("Which Z projection method should be used?");
 		Dialog.addChoice("", newArray("Average Intensity", "Max Intensity", "Min Intensity", "Sum Slices", "Standard Deviation", "Median"));
 	Dialog.addMessage("Which channel should be quantified?");
 		Dialog.addChoice("", newArray("1", "2", "3", "4")); 
 	Dialog.addMessage("Which channel should be used to draw your selection?");
 		Dialog.addChoice("", newArray("A. None", "B. No zone selection needed", "1", "2", "3", "4"));
 	Dialog.addMessage("How do you want your threshold value to be determined?");
 		Dialog.addChoice("",newArray("A. Using an algorithm", "B. Manual determination", "C. Conditional determination based on every images", "D. Conditional determination based on one image on two", "E. Conditional determination based on one image on five", "F. Conditional determination based on one image on ten", "G. Part 1 already done"));
 	Dialog.addMessage("");  
 Dialog.show();
  
  projectName = Dialog.getString();
  apeName = Dialog.getString();
  background = Dialog.getChoice();
  projMeth = Dialog.getChoice();
  workChan = Dialog.getChoice();
  drawChan = Dialog.getChoice();
  ThreshMeth = Dialog.getChoice();


print("\nPART 1 : \nCondition name: " + projectName + "\nExperimenter: " + apeName + "\nLocalization of treated file: " + dir + "\nNumbers of series in treated file: " + seriesCount + "\nBackground noise reduction methods: " + background + "\nZ-projection method: " + projMeth + "\nWorking channel: "+ workChan + "\nZone selection channel: " + drawChan + "\nThreshold determination method: " + ThreshMeth);

//Background noise choice
if (startsWith(background, "A.")) {
	protPersoB = 0;
	protPersoA = 0;
	background = 1;
}

if (startsWith(background, "B.")) {
	protPersoB = 1;
	protPersoA = 0;
	background = 0;
}

if (startsWith(background, "C.")) {
	protPersoB = 0;
	protPersoA = 1;
	background = 0;
}

if (startsWith(background, "D.")) {
	protPersoB = 1;
	protPersoA = 1;
	background = 0;
}

if (startsWith(background, "E.")) {
	protPersoB = 0;
	protPersoA = 0;
	background = 0;
}

// Selection zone choices
if (startsWith(drawChan, "A.")) {
	drawChan = 0;
}

if (startsWith(drawChan, "B.")) {
	drawChan = -2;
}

// Threshold methodology choices
if (startsWith(ThreshMeth, "A.")) {
	ThreshMeth = 0;
}

if (startsWith(ThreshMeth, "B.")) {
	ThreshMeth = 2;
	Pas = 1;
	ExlS = 1;
}

if (startsWith(ThreshMeth, "C.")) {		
	ThreshMeth = 4;
	Pas = 1;
	ExlS = 1;
	perc = 100;
}

if (startsWith(ThreshMeth, "D.")) {
	ThreshMeth = 6;
	Pas = 2;
	perc = 50;
}

if (startsWith(ThreshMeth, "E.")) {
	ThreshMeth = 6;
	Pas = 5;
	perc = 25;
}

if (startsWith(ThreshMeth, "F.")) {
	ThreshMeth = 6;
	Pas = 10;
	perc = 10;
}

if (startsWith(ThreshMeth, "G.")) {
	ThreshMeth = -1;
}

setTool("freehand");

//Part I
if (ThreshMeth > 1) {
	
	for (j=1; j<=seriesCount; j=j+Pas) {
   		run("Bio-Formats Importer", "open=[imageAdress] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+d2s(j,0));
   		fileNamej = "Series " + j;
		getDimensions(width, height, channels, slices, frames);
		
setTool("freehand");
		
		if (slices > 1) {
			rename("Stack");

			if (background == 1) {
				selectWindow("Stack");
				run("Median...", "radius=1 stack");
			}
			
			if (protPersoB == 1) {
				waitForUser("Apply your own protocol of background noise reduction\nThen click 'OK'");
			}

			run("Z Project...", "projection=[&projMeth]");
			rename("Projection");

			if (protPersoA == 1) {
				waitForUser("Apply your own protocol of background noise reduction\nThen click 'OK'");
			}
			
			selectWindow("Stack");
			run("Close");
			selectWindow("Projection");
			run("Duplicate...", "title=Duplication duplicate channels=&workChan");
			selectWindow("Projection");
			run("Close");
			selectWindow("Duplication");
			run("Grays");
			run("Maximize");
			run("Duplicate...", "title=&fileNamej duplicate channels=&workChan");			
			selectWindow(fileNamej);
			run("Grays");
			run("Maximize");
			run("Tile");

			Dialog.create("Image check");
		    	Dialog.addMessage("Do you want to treat this image?");
 				Dialog.addCheckbox("Do not take series " + j +" into account", false);
  			Dialog.show();
  			
  			out = Dialog.getCheckbox();
 	 		
 	 		if (out==false) {
 	 			setAutoThreshold("Default dark");
				setOption("BlackBackground", false);
				run("Threshold...");
				call("ij.plugin.frame.ThresholdAdjuster.setMode", "Red");
				waitForUser("Threshold selection", "Move the first cursor to choose your threshold. \n\n Then, click 'OK' on this window \n\n DO NOT click any button of the 'Threshold' window"); 
				getThreshold(lowerTh, upperTh);
				Th = lowerTh + Th;
				run("Close All");
				print("Threshold " + fileNamej + ": " + lowerTh);
				newImage(fileNamej, "16-bit black", j, 1, 1);
				run("Set...", "value=&lowerTh");
				run("Measure");
				run("Close All");
				c = c + 1;

				if(biggestThres < lowerTh) {
					biggestThres = lowerTh;
				}
 	 		}
			if (out==true) {
 	   			//The next part will happen only if the treated serie is not an actual stack, in this case, the serie will be excluded from the measure
   				print("\nYou have excluded series " + j + " from threshold determination");
   				run("Close All");
   				j=j-Pas+1;
 	   		}
   		} else {
   			//The next part will happen only if the treated serie is not an actual stack, in this case, the serie will be excluded from the measure
   			print("\nCaution, series " + j + " is not in the appropriate format");
   			run("Close All");
   			j=j-Pas+1;
   		}
   }
}

if (ThreshMeth > 1) {

	biggestThres = biggestThres + 0.1*biggestThres;
	Table.renameColumn("Area", "#Series");
	Table.renameColumn("Mean", "Threshold");
	Plot.create("Plot of Results", "#Series", "Threshold");
	Plot.add("Circle", Table.getColumn("#Series", "Results"), Table.getColumn("Threshold", "Results"));
	Plot.setStyle(0, "blue,#a0a0ff,1.0,Circle");
	Plot.show(); 
	Plot.setLimits(0,j,0.0,biggestThres);

	selectWindow("Plot of Results");
	saveAs("PNG", imageDirectory + "Graphe_Threshold_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".png");

	selectWindow("Results");
	Table.sort("Threshold");
	
	if (nResults % 2 == 0) {
		bas = (nResults/2)-1;
		Vbas=getResult("Threshold", bas);
		haut = bas+1;
		Vhaut=getResult("Threshold", haut);
		median = (Vhaut + Vbas)/2;
	
	} else {
		ma_valeur = ((nResults+1)/2)-1;
		median=getResult("Threshold", ma_valeur);
	}

	Table.sort("#Series");
	selectWindow("Results");
	run("Summarize");
	LSD = nResults -3;
	SD = getResult("Threshold", LSD);
	saveAs("Results", imageDirectory + "Threshold_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
   
	mean = Th / c;
	print("\nNumber of measure: " + c);
	print("Average threshold: " + mean);
	print("Median threshold: " + median);
	selectWindow("Results");
	IJ.renameResults("Threshold.xls"); 
 
	waitForUser("End of Part 1", "Start part 2?");

}

   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////     PART II     ///////////////////////////////////////////////////////////////
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
run("Set Measurements...", "area mean standard modal min centroid center perimeter bounding fit shape feret's integrated median skewness kurtosis area_fraction stack limit display redirect=None decimal=3");

//If part 1 already done is chosen
if (ThreshMeth < 0) {
	Dialog.create("Part 2");
		Dialog.addMessage("You have skipped Part 1, do you want to:");
		Dialog.addMessage("");
		Dialog.addCheckbox("Apply a fitted threshold per image", false);
		Dialog.addMessage("(Don't forget to load the excel \nfile with the name 'Threshold.xls' )");
		Dialog.addMessage("                                 OR");
		Dialog.addNumber("Apply a unique threshold value:", 0);
		Dialog.addMessage("________________________________________");
		Dialog.addMessage("");
		Dialog.addMessage("How do you want to retrieve the results?");
		Dialog.addCheckbox("Summarized (1 excel file per condition, 1 line per image)", true);
		Dialog.addCheckbox("Detailed (1 excel file per image, 1 line per object)", true);
		Dialog.addMessage("");
 	 	Dialog.addNumber("Objects' minimum size (pixel²): ", 0);
 	 	Dialog.addString("Objects' maximum size (pixel²): ", "Infinity");
 	 	Dialog.addMessage("");
 	 	Dialog.addNumber("Objects' minimum circularity (0.00): ", 0.00);
 	 	Dialog.addNumber("Objects' maximum circularity (1.00): ", 1.00);
  		Dialog.addMessage("");
  		Dialog.addNumber("First series to analyze: ", 1);
  		Dialog.addNumber("Last series to analyze: ", seriesCount);
	  	Dialog.addMessage("")
	Dialog.show();

	uniqueThres = Dialog.getCheckbox();
	Threshold = Dialog.getNumber();
	Summarize = Dialog.getCheckbox();
	Display = Dialog.getCheckbox();
	SL = Dialog.getNumber();
	SH = Dialog.getString();
	CL = Dialog.getNumber();
	CH = Dialog.getNumber();
	SerieD = Dialog.getNumber();
	SerieF = Dialog.getNumber();

table = 0;

	if (Summarize == true) {
		table = table + 1;
	}

	if (Display == true) {
		table = table + 2;
	}

	if (uniqueThres == true) {
		ExlS = 1 ;
		print("\nPART 2: \nA previously determined fitted threshold per image will be apply to the corresponding image \nObjects'minimum size: " + SL + "\nObjects'maximum size: " + SH + "\nObjects'minimum circularity: " + CL + "\nObjects'maximum circularity: " + CH + "\nFirst series to analyze: " + SerieD + "\nLast series to analyze: " + SerieF);
	}
	if (uniqueThres == false) {
		print("\nPART 2 : \nChosen threshold: " + Threshold + "\nObjects'minimum size: " + SL + "\nObjects'maximum size: " + SH + "\nObjects'minimum circularity: " + CL + "\nObjects'maximum circularity: " + CH + "\nFirst series to analyze: " + SerieD + "\nLast series to analyze: " + SerieF);
	}
}

//If thresholding by algorithm is chosen
if (ThreshMeth == 0) {
	Dialog.create("Part 2");
		Dialog.addMessage("You have choose to use an algorithm");
		Dialog.addMessage("");
		Dialog.addChoice("Which algorithm should be used?", newArray("Default", "Hyang", "Intermodes", "IsoData", "IJ_IsoData", "Li", "MaxEntropy", "Mean", "MinError", "Minimum", "Moments", "Otsu", "Percentile", "RenyiEntropy", "Shanbhag", "Triangle", "Yen"));
		Dialog.addMessage("");
		Dialog.addMessage("How do you want to retrieve the results?");
		Dialog.addCheckbox("Summarized (1 excel file per condition, 1 line per image)", true);
		Dialog.addCheckbox("Detailed (1 excel file per image, 1 line per object)", true);
		Dialog.addMessage("");
 	 	Dialog.addNumber("Objects' minimum size (pixel²): ", 0);
 	 	Dialog.addString("Objects' maximum size (pixel²): ", "Infinity");
 	 	Dialog.addMessage("");
  		Dialog.addNumber("Objects' minimum circularity (0.00): ", 0.00);
	  	Dialog.addNumber("Objects' maximum circularity (1.00): ", 1.00);
	  	Dialog.addMessage("");
	  	Dialog.addNumber("First series to analyze: ", 1);
	  	Dialog.addNumber("Last series to analyze: ", seriesCount);
	  	Dialog.addMessage("")
	Dialog.show();

	AlgoT = Dialog.getChoice();
	Summarize = Dialog.getCheckbox();
	Display = Dialog.getCheckbox();
	SL = Dialog.getNumber();
	SH = Dialog.getString();
	CL = Dialog.getNumber();
	CH = Dialog.getNumber();
	SerieD = Dialog.getNumber();
	SerieF = Dialog.getNumber();

table = 0;

	if (Summarize == true) {
		table = table + 1;
	}

	if (Display == true) {
		table = table + 2;
	}

	uniqueThres = false;
	print("\nPART 2: \nChosen algorithm: " + AlgoT + "\nObjects'minimum size: " + SL + "\nObjects'maximum size: " + SH + "\nObjects'minimum circularity: " + CL + "\nObjects'maximum circularity: " + CH + "\nFirst series to analyze: " + SerieD + "\nLast series to analyze: " + SerieF);
}

// If any of the C, D, E, F option of thresholding is chosen
if (ThreshMeth > 3) {

	selectWindow("Threshold.xls");
	run("Close");
	
    Dialog.create("Part 2");
  		 Dialog.addMessage("Average threshold of Part 1 is: " + mean); 
  		 Dialog.addMessage("Median threshold of Part 1 is: " + median); 
 		 Dialog.addNumber("Threshold : ", median);
		 Dialog.addMessage("");
 		 Dialog.addMessage("The file " + imageName + " contains " + seriesCount + " series.");
 		 Dialog.addMessage("");
		 Dialog.addMessage("How do you want to retrieve the results?");
		Dialog.addCheckbox("Summarized (1 excel file per condition, 1 line per image)", true);
		Dialog.addCheckbox("Detailed (1 excel file per image, 1 line per object)", true);
		 Dialog.addMessage("");
 		 Dialog.addNumber("Objects' minimum size (pixel²): ", 0);
		 Dialog.addString("Objects' maximum size (pixel²): ", "Infinity");
 		 Dialog.addMessage("");
 		 Dialog.addNumber("Objects' minimum circularity (0.00): ", 0.00);
 		 Dialog.addNumber("Objects' maximum circularity (1.00): ", 1.00);
 		 Dialog.addMessage("");
 		 Dialog.addNumber("First series to analyze: ", 1);
 		 Dialog.addNumber("Last series to analyze: ", seriesCount);
 	 Dialog.show();
 	 
 	 Threshold = Dialog.getNumber();
	 Summarize = Dialog.getCheckbox();
	 Display = Dialog.getCheckbox();
 	 SL = Dialog.getNumber();
 	 SH = Dialog.getString();
 	 CL = Dialog.getNumber();
 	 CH = Dialog.getNumber();
 	 SerieD = Dialog.getNumber();
 	 SerieF = Dialog.getNumber();

table = 0;

	if (Summarize == true) {
		table = table + 1;
	}

	if (Display == true) {
		table = table + 2;
	}

 	 uniqueThres = false;
 	 print("\nPART 2: \nChosen threshold: " + Threshold + "\nObjects'minimum size: " + SL + "\nObjects'maximum size: " + SH + "\nObjects'minimum circularity: " + CL + "\nObjects'maximum circularity: " + CH + "\nFirst series to analyze: " + SerieD + "\nLast series to analyze: " + SerieF);
}

//If the manual thresholding is chosen
if (ThreshMeth == 2) {
    Dialog.create("Part 2");
  		 Dialog.addMessage("The threshold you determine for each image \nwill be applied to each image"); 
		 Dialog.addMessage("");
 		 Dialog.addMessage("The file " + imageName + " contains " + seriesCount + " series.");
 		 Dialog.addMessage("");
 		 Dialog.addMessage("How do you want to retrieve the results?");
		Dialog.addCheckbox("Summarized (1 excel file per condition, 1 line per image)", true);
		Dialog.addCheckbox("Detailed (1 excel file per image, 1 line per object)", true);
		 Dialog.addMessage("");
 		 Dialog.addNumber("Objects' minimum size (pixel²): ", 0);
		 Dialog.addString("Objects' maximum size (pixel²): ", "Infinity");
 		 Dialog.addMessage("");
 		 Dialog.addNumber("Objects' minimum circularity (0.00): ", 0.00);
 		 Dialog.addNumber("Objects' maximum circularity (1.00): ", 1.00);
 		 Dialog.addMessage("");
 		 Dialog.addNumber("First series to analyze: ", 1);
 		 Dialog.addNumber("Last series to analyze: ", seriesCount);
 	 Dialog.show();

 	 Summarize = Dialog.getCheckbox();
	 Display = Dialog.getCheckbox();
 	 SL = Dialog.getNumber();
 	 SH = Dialog.getString();
 	 CL = Dialog.getNumber();
 	 CH = Dialog.getNumber();
 	 SerieD = Dialog.getNumber();
 	 SerieF = Dialog.getNumber();

table = 0;

	if (Summarize == true) {
		table = table + 1;
	}

	if (Display == true) {
		table = table + 2;
	}

	uniqueThres = false;
 	 print("\nObjects'minimum size: " + SL + "\nObjects'maximum size: " + SH + "\nObjects'minimum circularity: " + CL + "\nObjects'maximum circularity: " + CH + "\nFirst series to analyze: " + SerieD + "\nLast series to analyze: " + SerieF);
}

for (i=SerieD; i<=SerieF; i++) {
   	   		
	run("Close All");
	run("Bio-Formats Importer", "open=[imageAdress] autoscale color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT series_"+d2s(i,0));
	fileNamei = "Series " + i;
	getDimensions(width, height, channels, slices, frames);

	setTool("freehand");
	
	
	if (ThreshMeth == 2) {
		k=i-l;

		if (isOpen("Threshold.xls")) {

		selectWindow("Threshold.xls");
		SeriesCor = getResult("#Series", k);
			if (i==SeriesCor) {
				Threshold = getResult("Threshold", k);
				print("Threshold" + fileNamei + ": " + Threshold);
			}
			if (i!=SeriesCor) {
				print("Threshold" + fileNamei + ": Caution, this series was not treated in Part 1");
   				run("Close All");
   				l=l+1;
   				slices = -1;		
			}
		} else {
			waitForUser("Threshold window", "Please, open the excel file containing the threshold\nvalues (drag & drop) and make sure it is named\n \n    Threshold.xls\n \n \nTHEN click 'OK'");
			
			selectWindow("Threshold.xls");
		SeriesCor = getResult("#Series", k);
			if (i==SeriesCor) {
				Threshold = getResult("Threshold", k);
				print("Threshold" + fileNamei + ": " + Threshold);
			}
			if (i!=SeriesCor) {
				print("Threshold" + fileNamei + ": Caution, this series was not treated in Part 1");
   				run("Close All");
   				l=l+1;
   				slices = -1;		
			}
		}

	}

	if (uniqueThres == true) {
		k=i-l;
				if (isOpen("Threshold.xls")) {

		selectWindow("Threshold.xls");
		SeriesCor = getResult("#Series", k);
			if (i==SeriesCor) {
				Threshold = getResult("Threshold", k);
				print("Threshold" + fileNamei + ": " + Threshold);
			}
			if (i!=SeriesCor) {
				print("Threshold" + fileNamei + ": Caution, this series was not treated in Part 1");
   				run("Close All");
   				l=l+1;
   				slices = -1;		
			}
		} else {
			waitForUser("Threshold window", "Please, open the excel file containing the threshold\nvalues (drag & drop) and make sure it is named\n \n    Threshold.xls\n \n \nTHEN click 'OK'");
			
			selectWindow("Threshold.xls");
		SeriesCor = getResult("#Series", k);
			if (i==SeriesCor) {
				Threshold = getResult("Threshold", k);
				print("Threshold" + fileNamei + ": " + Threshold);
			}
			if (i!=SeriesCor) {
				print("Threshold" + fileNamei + ": Caution, this series was not treated in Part 1");
   				run("Close All");
   				l=l+1;
   				slices = -1;		
			}
		}
	}

	if (ThreshMeth == 4) {
		k=i-l;
		selectWindow("Threshold.xls");
		SeriesCor = getResult("#Series", k);
			if (i!=SeriesCor) {
				print("Threshold" + fileNamei + ": Caution, this series was not treated in Part 1");
   				run("Close All");
   				l=l+1;
   				slices = -1;		
			}
	}
	
	if (slices > 1) {
		rename("Stack");
		if (background == 1) {
			selectWindow("Stack");
			run("Median...", "radius=1 stack");
		}
			
		if (protPersoB == 1 ) {
			waitForUser("Apply your own protocol of background noise reduction\nThen click 'OK'");
		}

		run("Z Project...", "projection=[&projMeth]");
		rename("Projection");

		if (protPersoA == 1 ) {
			waitForUser("Apply your own protocole of background noise reduction\nThen click 'OK'");
		}
		
		selectWindow("Stack");
		run("Close");

		if (drawChan > 0) {
			selectWindow("Projection");
			run("Duplicate...", "title=DrawingChannel duplicate channels=&drawChan");
			run("Grays");
			run("Enhance Contrast", "saturated=0.35");
			run("Maximize");
		}
		
		selectWindow("Projection");
		run("Duplicate...", "title=&fileNamei duplicate channels=&workChan");
		selectWindow(fileNamei);
		run("Grays");
		run("Maximize");
		selectWindow("Projection");
		run("Close");
		run("Tile");

		if (ExlS == 0) {
			Dialog.create("Image check");
		    	Dialog.addMessage("Do you want to treat this image?");
 				Dialog.addCheckbox("Do not take series " + i +" into account", false);
  			Dialog.show();
  			
  			out = Dialog.getCheckbox();
		} else {
			out=false;
		}
 	 		
 	 	if (out==false) {

 	 		if (ThreshMeth != 0) {
 	 			selectWindow(fileNamei);
				setAutoThreshold("Default dark");
				setThreshold(Threshold, 65535);
				setOption("BlackBackground", false);
				selectWindow(fileNamei);
				run("Convert to Mask");

				if (drawChan > 0) {
					selectWindow("DrawingChannel");
					run("Maximize");
					waitForUser("Zone selection", "Draw region of interest, then click 'OK'.\n If you you want to apply the same ROI as previous series, juste click 'OK'");
					selectWindow(fileNamei);
					run("Restore Selection");
					run("Flatten");
					selectWindow(fileNamei+ "-1");
					saveAs("PNG", imageDirectory + "Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					selectWindow("Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					run("Close");
				}	

				if (drawChan == 0) {
					selectWindow(fileNamei);
					run("Maximize");
					waitForUser("Zone selection", "Draw region of interest, then click 'OK'.\n If you you want to apply the same ROI as previous series, juste click 'OK'");
					run("Flatten");
					selectWindow(fileNamei+ "-1");
					saveAs("PNG", imageDirectory + "Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					selectWindow("Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					run("Close");
				}
 	 		}

 	 		if (ThreshMeth == 0) { 
 	 			
 	 			if (drawChan > 0) {
 	 				selectWindow("DrawingChannel");
					run("Maximize");
					waitForUser("Zone selection", "Draw region of interest, then click 'OK'.\n If you you want to apply the same ROI as previous series, juste click 'OK'");
					selectWindow(fileNamei);
					run("Restore Selection");
					run("Flatten");
					selectWindow(fileNamei+ "-1");
					saveAs("PNG", imageDirectory + "Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					selectWindow("Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					run("Close");
				}
				
				if (drawChan == 0) {
					selectWindow(fileNamei);
					run("Maximize");
					waitForUser("Zone selection", "Draw region of interest, then click 'OK'.\n If you you want to apply the same ROI as previous series, juste click 'OK'");
					run("Flatten");
					selectWindow(fileNamei+ "-1");
					saveAs("PNG", imageDirectory + "Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					selectWindow("Image_" + fileNamei + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min +".png");
					run("Close");
				}
				
 	 			selectWindow(fileNamei);
 	 			setAutoThreshold(AlgoT + " dark");
				getThreshold(lowerTh, upperTh);
				setOption("BlackBackground", false);
				run("Convert to Mask");
				print("Threshold " + fileNamei + ": " + lowerTh);
				newImage(fileNamei, "16-bit black", i, 1, 1);
				run("Set...", "value=&lowerTh");
				run("Measure");
				saveAs("Results", imageDirectory + "Threshold_" + AlgoT + "_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
				selectWindow("Results");
				IJ.renameResults("Threshold " + AlgoT);

				if (drawChan > -1) {
					selectWindow(fileNamei);
					run("Restore Selection");
				}
 	 		}

 	 	selectWindow(fileNamei);

 	 	if (table == 1)	{	
		run("Analyze Particles...", "size=&SL-&SH circularity=&CL-&CH  show=[Bare Outlines] summarize");
		run("Input/Output...", "jpeg=85 gif=-1 file=.xls use_file copy_column copy_row save_column save_row");
		
		selectWindow("Summary");
		IJ.renameResults("Results"); 
		saveAs("Results", imageDirectory + "Summary_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Summary");
 	 	}

 	 	if (table == 2)	{	

 	 			if (i!=SerieD) {
					selectWindow("Display");
					IJ.renameResults("Results");
				}
	
		run("Analyze Particles...", "size=&SL-&SH circularity=&CL-&CH  show=[Bare Outlines] display ");
		run("Input/Output...", "jpeg=85 gif=-1 file=.xls use_file copy_column copy_row save_column save_row");

		selectWindow("Results");
		saveAs("Results", imageDirectory + "Detailed_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Display");
		
 	 	}

 	 	if (table == 3)	{	

 	  	 			if (i!=SerieD) {
					selectWindow("Display");
					IJ.renameResults("Results");
				}
				
		run("Analyze Particles...", "size=&SL-&SH circularity=&CL-&CH  show=[Bare Outlines] display summarize");
		run("Input/Output...", "jpeg=85 gif=-1 file=.xls use_file copy_column copy_row save_column save_row");

		selectWindow("Results");
		saveAs("Results", imageDirectory + "Detailed_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Display");
		
		selectWindow("Summary");
		IJ.renameResults("Results"); 
		saveAs("Results", imageDirectory + "Summary_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Summary");

 	 	}
 	 	
		if (ThreshMeth == 0) {
			selectWindow("Threshold " + AlgoT);
			IJ.renameResults("Results");
		}
		

		
		selectWindow("Log");
		saveAs("Text", imageDirectory + "Log_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".txt");
		run("Close All");
 	 	}
 	 	
 	 	if (out==true) {
   		print("\nSeries " + i + " has been excluded from analysis");
   		run("Close All");
   		selectWindow("Log");	
		saveAs("Text", imageDirectory + "Log_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".txt");
 	   	}
 	   	
	} else {
			
		if (slices == 1) {
   			print("\nCaution, Series " + i + " is not in the appropriate format");
   			
		} 
					
   		run("Close All");
		selectWindow("Log");
		saveAs("Text", imageDirectory + "Log_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".txt");	
		
	}
}


if (ThreshMeth == 0) {
	selectWindow("Results");
	saveAs("Results", imageDirectory + "Threshold_" + AlgoT + "_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
	selectWindow("Results");
	IJ.renameResults("Threshold " + AlgoT);
}
		
 	 	if (table == 1)	{	

		selectWindow("Summary");
		IJ.renameResults("Results"); 
		saveAs("Results", imageDirectory + "Summary_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Summary");
 	 	}

 	 	if (table == 2)	{	
		selectWindow("Results");
		saveAs("Results", imageDirectory + "Detailed_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Display");
		
 	 	}

 	 	if (table == 3)	{	
		selectWindow("Results");
		saveAs("Results", imageDirectory + "Detailed_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Display");
		
		selectWindow("Summary");
		IJ.renameResults("Results"); 
		saveAs("Results", imageDirectory + "Summary_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".xls");
		selectWindow("Results");
		IJ.renameResults("Summary");

 	 	} 
print("\nAnalysis done with CASQITO macro v17 by Juliette de Noiron, June 2021, under GNU License v3");

selectWindow("Log");
saveAs("Text", imageDirectory + "Log_" + projectName + " _ " + year + "y " + day + "d " + month + "m " + hour + "h" + min + ".txt");	
run("Close All");
