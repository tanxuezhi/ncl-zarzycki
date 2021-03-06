;========================================================
; This file reads in a traj file produced by the TC tracker
; and produces a lat-lon plot of trajectories color-coded by intensity
;========================================================
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/u/home/zarzycki/ncl/functions/plot_outline_fcn.ncl"
;========================================================
begin



ibstyr=1980
ibenyr=2012

numyears=tofloat(ibenyr-ibstyr+1)



factor=1.0
ms_to_kts = 1.94384449
ibcutwindArr = (/0.0,17.0,33.0,51.0/) ;MUST BE INCREASING!

wcStrt     = systemfunc("date")

print("Plotting iBtracks data from: "+ibstyr+" to "+ibenyr)
print("Loading data, this may take awhile.")
ibdir = "/glade/u/home/zarzycki/work/ibtracs/"
ibfilename="Allstorms.ibtracs_wmo.v03r08.nc"

ibfile = addfile(ibdir+ibfilename,"r")

;=============================================================================
; Here we'll find the storm # bounds so we don't have to load full dataset
;=============================================================================
ibyear = toint(ibfile->season)
print("num storms "+dimsizes(ibyear))
print("Figuring out what storms we need to take")
; We'll do one year on either side because I'm too lazy to split up SH years.
ibyear = where(ibyear .lt. ibstyr-1,-1,ibyear)
ibyear = where(ibyear .gt. ibenyr+1,-1,ibyear)

; loop forwards to find first instance of valid year
do i = 0,dimsizes(ibyear)-1
  if(ibyear(i).gt.0) then
    stix = i
    break
  end if
end do

; loop backwards to find last instance of valid year
do i = dimsizes(ibyear)-1,0,1
  if(ibyear(i).gt.0) then
    enix = i
    break
  end if
end do
print("Starting index: "+stix+"     end index: "+enix)

delete(ibyear)
;=============================================================================

iblat = ibfile->lat_wmo(stix:enix,:)*.01
iblon = ibfile->lon_wmo(stix:enix,:)*.01
ibtype = toint(ibfile->nature_wmo(stix:enix,:))
ibwind_ = ibfile->wind_wmo(stix:enix,:)*.1/ms_to_kts
ibpres = ibfile->pres_wmo(stix:enix,:)*.1*100.
ibtime = ibfile->time_wmo(stix:enix,:)
ibnamechar = ibfile->name(stix:enix,:)

iblon=where(iblon.lt.0,iblon+360.,iblon)

ibbasin = byte2flt(ibfile->sub_basin(stix:enix,:))

stDateIBUnits=cd_inv_calendar(ibstyr,1,1,0,0,0,ibtime@units,0)
enDateIBUnits=cd_inv_calendar(ibenyr,12,31,23,0,0,ibtime@units,0)

ibstormcount=dimsizes(ibfile->season(stix:enix))
ibsizes = dimsizes(iblat)
ibntimes = ibsizes(1)

; Need to convert char to str for name
ibnamesingle = new(ibstormcount,"string")
do i = 0,ibstormcount-1
  ibnamesingle(i)=oneDtostring(ibnamechar(i,:))
  ibnamesingle(i)=str_sub_str(ibnamesingle(i),",","")
end do

ibname = conform(ibwind_,ibnamesingle,0)

; Needed to correct for weird IBTrACS issues with .0000000005 times, etc.
ibtime = decimalPlaces(ibtime,3,True)

ibwind_ = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibwind_,ibwind_@_FillValue)
ibpres = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibpres,ibpres@_FillValue)
iblat = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblat,iblat@_FillValue)
iblon = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,iblon,iblon@_FillValue)
ibtime = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibtime,ibtime@_FillValue)
ibname = where(ibtime .ge. stDateIBUnits .and. ibtime .le. enDateIBUnits,ibname,ibname@_FillValue)

; Correct for non-standard times
eps=0.00001
ibwind_ = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibwind_@_FillValue,ibwind_)
ibpres = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibpres@_FillValue,ibpres)
iblat  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblat@_FillValue,iblat)
iblon  = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,iblon@_FillValue,iblon)
ibtime = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibtime@_FillValue,ibtime)
ibname = where(mod(ibtime,0.25) .ge. eps .or. mod(ibtime,0.25) .le. -eps,ibname@_FillValue,ibname)

;=============================================================================
; Load optional PHIS file
;=============================================================================

phisfile=addfile("/glade/u/home/zarzycki/work/cam_tools/hires-topo/2deg_cesm_topo_latlon.nc","r")
PHIS=phisfile->PHIS



;=============================================================================


;system("echo "+quote+             +quote+" >> "+filename)
quote = inttochar(34)
delim="	"
filename="./test.txt"

do ii = 0,ibstormcount-1
  ;print(ibname(ii,0)+" "+toint(ibbasin(ii,0)))
  if (toint(ibbasin(ii,0)) .eq. 0 .or. toint(ibbasin(ii,0)) .eq. 12 .or. toint(ibbasin(ii,0)) .eq. 13) then
  ;if (toint(ibbasin(ii,0)) .eq. 0 ) then
    if (.not.ismissing(ibname(ii,0))) then

      thisdate=cd_calendar(ibtime(ii,0),0)
      numentries=num(.not.ismissing(iblat(ii,:)))
      print("    ")
      ;header=ibname(ii,0)
      header="start"
      HEADSTR=header+delim+numentries+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)
      print(HEADSTR+"")
      system("echo "+quote+      HEADSTR      +quote+" >> "+filename)



      do jj = 0,ibntimes-1
        if (.not.ismissing(iblat(ii,jj))) then
          
          ;print(iblat(ii,jj)+" "+iblon(ii,jj))
          if (iblon(ii,jj) .le. max(PHIS&lon) .and. iblon(ii,jj) .ge. min(PHIS&lon)) then
            thisPHIS=tofloat(PHIS({iblat(ii,jj)},{iblon(ii,jj)}))
          else
            thisPHIS=tofloat(PHIS({iblat(ii,jj)},{max(PHIS&lon)}))
          end if

          thisdate=cd_calendar(ibtime(ii,jj),0)
          STORMSTR=delim+"-99999"+delim+iblon(ii,jj)+delim+iblat(ii,jj)+delim+ibpres(ii,jj)+delim+ibwind_(ii,jj)+delim+sprintf("%7.3e", thisPHIS)+delim+thisdate(0,0)+delim+thisdate(0,1)+delim+thisdate(0,2)+delim+thisdate(0,3)
          print(STORMSTR+"")
          system("echo "+quote+      STORMSTR       +quote+" >> "+filename)
        end if
      end do
    end if
  end if
end do
end
  
	;13056	41.470669	-19.662915	9.957811e+04	1.960049e+01	1979	1	16	12	
