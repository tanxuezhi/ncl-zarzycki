;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "../../../functions/getTrajectories.ncl"
;========================================================
begin

output_type="pdf"

configArr=(/"B20TRC5CNBDRD","BRCP85C5CNBDRD","BRCP85C5CNBDRD"/)
yearsArr=(/"1990010100Z-2005123118Z","2026010100Z-2035123118Z","2071010100Z-2080123118Z"/)
f1990=addfile("/glade/u/home/zarzycki/scratch/LENS-snow/climo/b.e11.B20TRC5CNBDRD.f09_g16.ENS.cam.h2.PRECT_SNOW.1990010100Z-2005123118Z_AVG.nc","r")
f2026=addfile("/glade/u/home/zarzycki/scratch/LENS-snow/climo/b.e11.BRCP85C5CNBDRD.f09_g16.ENS.cam.h2.PRECT_SNOW.2026010100Z-2035123118Z_AVG.nc","r")
f2071=addfile("/glade/u/home/zarzycki/scratch/LENS-snow/climo/b.e11.BRCP85C5CNBDRD.f09_g16.ENS.cam.h2.PRECT_SNOW.2071010100Z-2080123118Z_AVG.nc","r")

SWE=12.

SNOW1990=f1990->PRECT_SNOW(0,:,:)
SNOW1990 = SNOW1990*3.402e+6  ; now inches per day
SNOW1990 = SNOW1990*365. ; now inches per year
SNOW1990 = SNOW1990*SWE  ; now inches SNOW1990 per year

SNOW2026=f2026->PRECT_SNOW(0,:,:)
SNOW2026 = SNOW2026*3.402e+6  ; now inches per day
SNOW2026 = SNOW2026*365. ; now inches per year
SNOW2026 = SNOW2026*SWE  ; now inches SNOW2026 per year

SNOW2071=f2071->PRECT_SNOW(0,:,:)
SNOW2071 = SNOW2071*3.402e+6  ; now inches per day
SNOW2071 = SNOW2071*365. ; now inches per year
SNOW2071 = SNOW2071*SWE  ; now inches SNOW2071 per year

SNOW2071DIFF=SNOW2071
SNOW2071DIFF=SNOW2071-SNOW1990
SNOW2026DIFF=SNOW2026
SNOW2026DIFF=SNOW2026-SNOW1990

wks = gsn_open_wks(output_type,"./pdf/seasonal-mean-LENS")               ; open workstation
nplots=6
map = new(nplots,"graphic")

res                     = True         ; plot modifications desired
res@gsnDraw=False
res@gsnFrame=False
res@cnFillOn            = True         ; Turn on contour fill
res@cnLinesOn           = True        ; Turn off contour lines
res@cnLineLabelsOn      = False        ; Turn off contour line labels
res@lbLabelAutoStride   = True         ; Clean up labelbar labels.

res@mpOceanFillColor = "White"
res@cnFillDrawOrder             = "PreDraw"
res@cnLineDrawOrder             = "PreDraw"
res@mpFillAreaSpecifiers        = (/"Land"/)
res@mpSpecifiedFillColors       = (/"transparent"/)
res@mpOutlineDrawOrder = "Draw"


;res@cnFillMode          = "RasterFill"
res@gsnAddCyclic = False

res@mpMinLatF             = 38.
res@mpMaxLatF             = 48.
res@mpMinLonF             = 279.
res@mpMaxLonF             = 293.
res@mpCenterLonF = 286.

res@lbLabelBarOn        = False           ; turn off individual cb's


res@mpOutlineOn                 = True

res@mpUSStateLineThicknessF     = 2.5  ; 2-1/2 times as thick.
res@mpGeophysicalLineThicknessF = 2.5

res@mpOutlineBoundarySets       = "GeophysicalAndUSStates"
res@mpOutlineSpecifiers         = (/"Land","Conterminous US:states"/)

res@gsnStringFontHeightF=0.027

resavg=res

cmap = read_colormap_file("wxbell_snow.rgb")
;cmap = read_colormap_file("MPL_StepSeq")
resavg@cnFillPalette       = cmap(::-1,:)
delete(cmap)
resavg@cnLevelSelectionMode = "ExplicitLevels"
resavg@cnLevels    = (/  6., 12., 18., 24., 30., 36., 48., 60., 72., 84., 96., 120./)



resavg@tiMainString=""
resavg@gsnRightString="in. snow/yr"
resavg@gsnLeftString="Annual snowfall (1990-2015)"
map(0) = gsn_csm_contour_map_ce(wks,SNOW1990,resavg)
resavg@gsnLeftString="Annual snowfall (2026-2035)"
map(1) = gsn_csm_contour_map_ce(wks,SNOW2026,resavg)
resavg@gsnLeftString="Annual snowfall (2071-2080)"
map(2) = gsn_csm_contour_map_ce(wks,SNOW2071,resavg)

resdiff=res

cmap = read_colormap_file("temp_diff_18lev")
resdiff@cnFillColors = cmap(::-1,:)    ; Skips the first two colors
delete(cmap)
resdiff@cnLevelSelectionMode = "ManualLevels"
resdiff@cnLevelSpacingF      =  5.0
resdiff@cnMinLevelValF       =  -35.0
resdiff@cnMaxLevelValF       =  35.0


resdiff@gsnRightString="in. snow/yr"

resdiff@gsnLeftString="Snowfall change in 2026-2035"
map(4) = gsn_csm_contour_map_ce(wks,SNOW2026DIFF,resdiff)
resdiff@gsnLeftString="Snowfall change in 2071-2080"
map(5) = gsn_csm_contour_map_ce(wks,SNOW2071DIFF,resdiff)

;************************************************
; create panel
;************************************************
  pres                  = True
  pres@gsnMaximize      = True
  pres@gsnFrame         = False
  pres@gsnPanelLabelBar = True
  pres@pmLabelBarWidthF = 0.8
pres@lbLabelStride = 2
;
; Panel the first set of plots without drawing them, so we
; can retrieve the bounding boxes and calculate the height.
;
  pres@gsnDraw = False
;
; "gsn_panel_return" is an unadvertised function. It behaves
; the same as "gsn_panel", except it returns all the objects 
; being paneled, including the labelbar if there is one.
;
  pplots = gsn_panel_return(wks,map(0:2),(/1,3/),pres)
;
; Retrieve bounding boxes of all objects created by gsn_panel call.
;
; max(bb(:,0)) is the topmost location of all combined objects,
; and min(bb(:,1)) is the bottommost.
;
  bb     = NhlGetBB(pplots)
  height = max(bb(:,0)) - min(bb(:,1))

;---Using height value, now we can panel all sets of plots.
  pres@gsnDraw                          = True
  pres@gsnPanelTop                      = 0.9   ; leave room for title
  pres@gsnPanelBottom                   = pres@gsnPanelTop - height

;---figure string resources
  pres@gsnPanelFigureStringsPerimOn     = True
  pres@gsnPanelFigureStringsFontHeightF = 0.015
  pres@amJust                           = "TopLeft"

;---Main title, only on first set of plots
  pres@txString = "LENS ensemble mean annual snowfall"

  fig_strs = (/"a","b","c","d","e","f"/) + "."
  do n=0,nplots-1,3
    pres@gsnPanelFigureStrings = fig_strs(n:n+2)
    gsn_panel(wks,map(n:n+2),(/1,3/),pres)

;---Set for the next panel call.
    pres@txString = ""
    pres@gsnPanelTop    = pres@gsnPanelBottom
    pres@gsnPanelBottom = pres@gsnPanelTop-height
  end do
  frame(wks)

end

