!
!  wrapper for the main data read
!  ensures that same procedure occurs on initial read as from menu option
!
!  drives reading of all files listed on command line
!
!  Arguments:
!   ireadfile : if < 0, reads from all files
!               if > 0, reads only from the filename rootname(ireadfile)
!               if = 0, no data read, just call labelling and exact_params
!
module getdata
 implicit none
 public :: get_data

 private

contains

subroutine get_data(ireadfile,gotfilenames,firsttime)
  use exact, only:read_exactparams
  use filenames
  use limits, only:set_limits,read_limits
  use settings_data
  use settings_part, only:iexact,icoordsnew
  use particle_data
  use prompting
  use labels, only:label,labelvec,iamvec
  use geometry, only:labelcoord
  implicit none
  integer, intent(in) :: ireadfile
  logical, intent(in) :: gotfilenames
  logical, intent(in), optional :: firsttime
  logical :: setlimits
  integer :: i,istart,ierr

  if (.not.gotfilenames) then
     if (nfiles.le.0 .or. nfiles.gt.maxfile) nfiles = 1
     call prompt(' Enter number of files to read ',nfiles,1,maxfile)
     do i=1,nfiles
        call prompt(' Enter filename to read',rootname(i))
     enddo
  endif
  !
  !--set everything to zero initially
  !
  ncolumns = 0
  ncalc = 0
  n_end = 0
  istart = 1
  ivegotdata = .false.
  ifileopen = ireadfile

  if (ireadfile.le.0) then
     !
     !--read all steps from the data file
     !
     nstepsinfile(1:nfiles) = 0
     print*,'reading from all dumpfiles...'
     do i=1,nfiles
        call read_data(rootname(i),istart,nstepsinfile(i))
        istart = istart + nstepsinfile(i) ! number of next step in data array
     enddo
     nstart = 1
     n_end = istart - 1
     nstepstotal = n_end
     numplot = ncolumns
     if (nstepstotal.gt.0) ivegotdata = .true.
     print "(a,i6,a,i3)",' >> Finished data read, nsteps = ',nstepstotal,' ncolumns = ',numplot

     !
     !--set labels for each column of data
     !
     print*,'setting plot labels...'
     call set_labels
     !
     !--calculate various additional quantities
     !
     if (n_end.ge.nstart) then
        call calc_quantities(nstart,n_end)
     endif
     !
     !--read plot limits from file, otherwise set plot limits
     !
     call read_limits(ierr)
     if (ierr.gt.0 .and. ivegotdata .and. nstepsinfile(1).ge.1) then
        call set_limits(nstart,n_end,1,numplot)
     endif
     
  elseif (ireadfile.gt.0) then
     !
     !--read from a single file only
     !
     nstepsinfile(ireadfile) = 0
     print*,'reading single dumpfile'
     call read_data(rootname(ireadfile),istart,nstepsinfile(ireadfile))
     !!print*,'nsteps in file = ',nstepsinfile(ireadfile)
     if (ANY(nstepsinfile(1:ireadfile).gt.0)) ivegotdata = .true.
     !
     !--assume there are the same number of steps in the other files
     !  which have not been read
     !
     do i=1,nfiles
        if (nstepsinfile(i).eq.0) then
           nstepsinfile(i) = nstepsinfile(ireadfile)
        endif
     enddo
     nstart = 1
     n_end = sum(nstepsinfile(1:nfiles))
     nstepstotal = n_end
     numplot = ncolumns
     !
     !--set labels for each column of data
     !
     !!print*,'setting plot labels...'
     call set_labels
     !
     !--calculate various additional quantities
     !
     if (nstepsinfile(ireadfile).gt.0) then
        call calc_quantities(1,nstepsinfile(ireadfile))
     endif
     
     !
     !--only set limits if reading the first file for the first time
     !  
     setlimits = (ireadfile.eq.1 .and. ivegotdata .and. nstepsinfile(1).ge.1)     
     if (.not.present(firsttime)) then
        setlimits = .false.
     elseif (.not.firsttime) then
        setlimits = .false.
     endif
       
     if (setlimits) then
        call set_limits(1,nstepsinfile(ireadfile),1,numplot)
     endif
  endif
!
!--reset coordinate and vector labels depending on coordinate system)
!
  if (icoords.ne.0 .or. icoordsnew.ne.0) then
     label(1:ndim) = labelcoord(1:ndim,icoordsnew)
     do i=1,numplot
        if (iamvec(i).ne.0) then
           label(i) = trim(labelvec(iamvec(i)))//'\d'//labelcoord(i-iamvec(i)+1,icoordsnew)
        endif
     enddo
  endif
  !
  !--read exact solution parameters from files if present
  !
  if (iexact.ne.0) then
     if (ireadfile.lt.0) then
        call read_exactparams(iexact,rootname(1),ierr)
     else
        call read_exactparams(iexact,rootname(ireadfile),ierr)
     endif
  endif
  
  return
end subroutine get_data

end module getdata
