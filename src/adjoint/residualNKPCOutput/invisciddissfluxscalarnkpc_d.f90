   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.4 (r3375) - 10 Feb 2010 15:08
   !
   !  Differentiation of invisciddissfluxscalarnkpc in forward (tangent) mode:
   !   variations   of useful results: dwadj wadj
   !   with respect to varying inputs: sigma padj radkadj radjadj
   !                dwadj wadj radiadj
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          inviscidDissFluxScalarAdj.f90                   *
   !      * Author:        Edwin van der Weide,C.A.(Sandy) Mader           *
   !      * Starting date: 06-10-2009                                      *
   !      * Last modified: 06-10-2009                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   SUBROUTINE INVISCIDDISSFLUXSCALARNKPC_D(wadj, wadjd, padj, padjd, dwadj&
   &  , dwadjd, radiadj, radiadjd, radjadj, radjadjd, radkadj, radkadjd, &
   &  icell, jcell, kcell, nn, level, sps)
   USE FLOWVARREFSTATE
   USE CGNSGRID
   USE BLOCKPOINTERS
   USE INPUTADJOINT
   USE INPUTTIMESPECTRAL
   USE INPUTPHYSICS
   USE INPUTDISCRETIZATION
   USE CONSTANTS
   USE ITERATION
   IMPLICIT NONE
   !
   !      ******************************************************************
   !      *                                                                *
   !      * inviscidDissFluxScalar computes the scalar artificial          *
   !      * dissipation, see AIAA paper 81-1259, for a given block.        *
   !      * Therefore it is assumed that the pointers in  blockPointers    *
   !      * already point to the correct block.                            *
   !      *                                                                *
   !      ******************************************************************
   !
   !nTimeIntervalsSpectral
   !
   !      Subroutine arguments
   !
   INTEGER(kind=inttype) :: icell, jcell, kcell, nn, level, sps
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral), INTENT(INOUT) :: wadj
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, nw, &
   &  ntimeintervalsspectral), INTENT(INOUT) :: wadjd
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: padj
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2, &
   &  ntimeintervalsspectral), INTENT(IN) :: padjd
   REAL(kind=realtype), DIMENSION(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral) :: radiadj, radjadj, radkadj
   REAL(kind=realtype), DIMENSION(-1:1, -1:1, -1:1, &
   &  ntimeintervalsspectral) :: radiadjd, radjadjd, radkadjd
   REAL(kind=realtype), DIMENSION(nw, ntimeintervalsspectral), INTENT(&
   &  INOUT) :: dwadj
   REAL(kind=realtype), DIMENSION(nw, ntimeintervalsspectral), INTENT(&
   &  INOUT) :: dwadjd
   !
   !      Local parameter.
   !
   REAL(kind=realtype), PARAMETER :: dssmax=0.25_realType
   !
   !      Local variables.
   !
   INTEGER(kind=inttype) :: i, j, k, ind
   INTEGER(kind=inttype) :: ii, jj, kk
   REAL(kind=realtype) :: sslim, rhoi
   REAL(kind=realtype) :: rhoid
   REAL(kind=realtype) :: sfil, fis2, fis4
   REAL(kind=realtype) :: ppor, rrad, dis2, dis4
   REAL(kind=realtype) :: rradd, dis2d, dis4d
   REAL(kind=realtype) :: dss1, dss2, ddw, fs
   REAL(kind=realtype) :: dss1d, dss2d, ddwd, fsd
   REAL(kind=realtype) :: fact
   !real(kind=realType), dimension(0:ib,0:jb,0:kb) :: ss
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2) :: ss
   REAL(kind=realtype), DIMENSION(-2:2, -2:2, -2:2) :: ssd
   REAL(kind=realtype) :: min5d
   REAL(kind=realtype) :: x6d
   REAL(kind=realtype) :: y4d
   REAL(kind=realtype) :: min6
   REAL(kind=realtype) :: min5
   REAL(kind=realtype) :: min4
   REAL(kind=realtype) :: min3
   REAL(kind=realtype) :: min2
   REAL(kind=realtype) :: min1
   INTRINSIC MAX
   REAL(kind=realtype) :: x6
   REAL(kind=realtype) :: x5
   REAL(kind=realtype) :: min1d
   REAL(kind=realtype) :: x4
   REAL(kind=realtype) :: x3
   INTRINSIC ABS
   REAL(kind=realtype) :: x2
   REAL(kind=realtype) :: x2d
   REAL(kind=realtype) :: x1
   REAL(kind=realtype) :: min4d
   REAL(kind=realtype) :: x5d
   REAL(kind=realtype) :: y3d
   REAL(kind=realtype) :: y6d
   REAL(kind=realtype) :: x1d
   REAL(kind=realtype) :: min3d
   REAL(kind=realtype) :: x4d
   REAL(kind=realtype) :: y2d
   REAL(kind=realtype) :: min6d
   REAL(kind=realtype) :: y5d
   INTRINSIC MIN
   REAL(kind=realtype) :: y6
   REAL(kind=realtype) :: y5
   REAL(kind=realtype) :: min2d
   REAL(kind=realtype) :: y4
   REAL(kind=realtype) :: y3
   REAL(kind=realtype) :: y2
   REAL(kind=realtype) :: x3d
   REAL(kind=realtype) :: y1
   REAL(kind=realtype) :: y1d
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Begin execution                                                *
   !      *                                                                *
   !      ******************************************************************
   !
   ! Check if rFil == 0. If so, the dissipative flux needs not to
   ! be computed.
   IF (rfil .EQ. zero) THEN
   RETURN
   ELSE
   !!$           ! Viscous case. Pressure switch is based on the entropy.
   !!$           ! Also set the value of sslim. To be fully consistent this
   !!$           ! must have the dimension of entropy and it is therefore
   !!$           ! set to a fraction of the free stream value.
   !!$
   !!$           sslim = 0.001_realType*pInfCorr/(rhoInf**gammaInf)
   !!$
   !!$           ! Store the entropy in ss. Only fill the entries used in
   !!$           ! the discretization, i.e. ignore the corner halo's.
   !!$
   ! Determine the variables used to compute the switch.
   ! For the inviscid case this is the pressure; for the viscous
   ! case it is the entropy.
   SELECT CASE  (equations) 
   CASE (eulerequations) 
   ! Inviscid case. Pressure switch is based on the pressure.
   ! Also set the value of sslim. To be fully consistent this
   ! must have the dimension of pressure and it is therefore
   ! set to a fraction of the free stream value.
   sslim = 0.001_realType*pinfcorr
   ssd = 0.0
   ! Copy the pressure in ss. Only fill the entries used in
   ! the discretization, i.e. ignore the corner halo's.
   !do we need to ignore the corners in the ADjoint?... leave in for now...
   !0,kb
   DO k=-2,2
   !2,jl
   DO j=-2,2
   !2,il
   DO i=-2,2
   ssd(i, j, k) = padjd(i, j, k, sps)
   ss(i, j, k) = padj(i, j, k, sps)
   END DO
   END DO
   END DO
   CASE (nsequations, ransequations) 
   !===============================================================
   PRINT*, 'NSEquations and RANSEquations not yet supported'
   STOP
   CASE DEFAULT
   ssd = 0.0
   END SELECT
   ! Set a couple of constants for the scheme.
   fis2 = rfil*vis2
   fis4 = rfil*vis4
   sfil = one - rfil
   ! Replace the total energy by rho times the total enthalpy.
   ! In this way the numerical solution is total enthalpy preserving
   ! for the steady Euler equations. Also replace the velocities by
   ! the momentum. Only done for the entries used in the
   ! discretization, i.e. ignore the corner halo's.
   !0,kb
   DO k=-2,2
   !2,jl
   DO j=-2,2
   !2,il
   DO i=-2,2
   wadjd(i, j, k, ivx, sps) = wadjd(i, j, k, irho, sps)*wadj(i, j&
   &            , k, ivx, sps) + wadj(i, j, k, irho, sps)*wadjd(i, j, k, ivx&
   &            , sps)
   wadj(i, j, k, ivx, sps) = wadj(i, j, k, irho, sps)*wadj(i, j, &
   &            k, ivx, sps)
   wadjd(i, j, k, ivy, sps) = wadjd(i, j, k, irho, sps)*wadj(i, j&
   &            , k, ivy, sps) + wadj(i, j, k, irho, sps)*wadjd(i, j, k, ivy&
   &            , sps)
   wadj(i, j, k, ivy, sps) = wadj(i, j, k, irho, sps)*wadj(i, j, &
   &            k, ivy, sps)
   wadjd(i, j, k, ivz, sps) = wadjd(i, j, k, irho, sps)*wadj(i, j&
   &            , k, ivz, sps) + wadj(i, j, k, irho, sps)*wadjd(i, j, k, ivz&
   &            , sps)
   wadj(i, j, k, ivz, sps) = wadj(i, j, k, irho, sps)*wadj(i, j, &
   &            k, ivz, sps)
   wadjd(i, j, k, irhoe, sps) = wadjd(i, j, k, irhoe, sps) + &
   &            padjd(i, j, k, sps)
   wadj(i, j, k, irhoe, sps) = wadj(i, j, k, irhoe, sps) + padj(i&
   &            , j, k, sps)
   END DO
   END DO
   END DO
   !Following method in the upwind scheme, take the residual onto dwAdj instead 
   !of a separate fw. If it needs to be switched back, fw is dissiptive, dw is
   !inviscid...
   !!$       ! Initialize the dissipative residual to a certain times,
   !!$       ! possibly zero, the previously stored value. Owned cells
   !!$       ! only, because the halo values do not matter.
   !
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Dissipative fluxes in the i-direction.                         *
   !      *                                                                *
   !      ******************************************************************
   ! 
   !set some indices for use later
   i = icell - 1
   j = jcell
   k = kcell
   fact = one
   !do k=2,kl
   !  do j=2,jl
   ! Compute the pressure sensor in the first cell, which
   ! is a halo cell.
   !!dss1 = abs((ss(2,j,k) - two*ss(1,j,k) + ss(0,j,k)) &
   !!     /     (ss(2,j,k) + two*ss(1,j,k) + ss(0,j,k) + sslim))
   ! Loop in i-direction.
   DO ii=-1,0
   x1d = ((ssd(ii+1, 0, 0)-two*ssd(ii, 0, 0)+ssd(ii-1, 0, 0))*(ss(ii+&
   &        1, 0, 0)+two*ss(ii, 0, 0)+ss(ii-1, 0, 0)+sslim)-(ss(ii+1, 0, 0)-&
   &        two*ss(ii, 0, 0)+ss(ii-1, 0, 0))*(ssd(ii+1, 0, 0)+two*ssd(ii, 0&
   &        , 0)+ssd(ii-1, 0, 0)))/(ss(ii+1, 0, 0)+two*ss(ii, 0, 0)+ss(ii-1&
   &        , 0, 0)+sslim)**2
   x1 = (ss(ii+1, 0, 0)-two*ss(ii, 0, 0)+ss(ii-1, 0, 0))/(ss(ii+1, 0&
   &        , 0)+two*ss(ii, 0, 0)+ss(ii-1, 0, 0)+sslim)
   IF (x1 .GE. 0.) THEN
   dss1d = x1d
   dss1 = x1
   ELSE
   dss1d = -x1d
   dss1 = -x1
   END IF
   x2d = ((ssd(ii+2, 0, 0)-two*ssd(ii+1, 0, 0)+ssd(ii, 0, 0))*(ss(ii+&
   &        2, 0, 0)+two*ss(ii+1, 0, 0)+ss(ii, 0, 0)+sslim)-(ss(ii+2, 0, 0)-&
   &        two*ss(ii+1, 0, 0)+ss(ii, 0, 0))*(ssd(ii+2, 0, 0)+two*ssd(ii+1, &
   &        0, 0)+ssd(ii, 0, 0)))/(ss(ii+2, 0, 0)+two*ss(ii+1, 0, 0)+ss(ii, &
   &        0, 0)+sslim)**2
   x2 = (ss(ii+2, 0, 0)-two*ss(ii+1, 0, 0)+ss(ii, 0, 0))/(ss(ii+2, 0&
   &        , 0)+two*ss(ii+1, 0, 0)+ss(ii, 0, 0)+sslim)
   IF (x2 .GE. 0.) THEN
   dss2d = x2d
   dss2 = x2
   ELSE
   dss2d = -x2d
   dss2 = -x2
   END IF
   !print *,'dss2',dss2
   ! Compute the dissipation coefficients for this face.
   ppor = zero
   IF (pori(i, j, k) .EQ. normalflux) ppor = half
   !rrad = ppor*(radI(i,j,k) + radI(i+1,j,k))
   rradd = ppor*(radiadjd(ii, 0, 0, sps)+radiadjd(ii+1, 0, 0, sps))
   rrad = ppor*(radiadj(ii, 0, 0, sps)+radiadj(ii+1, 0, 0, sps))
   !print *,'radI',radIAdj(ii,0,0),radI(icell+ii,jcell,kcell),icell,jcell,kcell,radIAdj(ii+1,0,0),radI(icell+ii+1,jcell,kcell)
   !lumped Dissipation for preconditioner
   IF (lumpeddiss) THEN
   IF (dss1 .LT. dss2) THEN
   y1d = dss2d
   y1 = dss2
   ELSE
   y1d = dss1d
   y1 = dss1
   END IF
   IF (dssmax .GT. y1) THEN
   min1d = y1d
   min1 = y1
   ELSE
   min1 = dssmax
   min1d = 0.0
   END IF
   dis2d = fis2*(rradd*min1+rrad*min1d) + sigma*fis4*rradd
   dis2 = fis2*rrad*min1 + sigma*fis4*rrad
   dis4 = 0.0
   dis4d = 0.0
   ELSE
   IF (dss1 .LT. dss2) THEN
   y2d = dss2d
   y2 = dss2
   ELSE
   y2d = dss1d
   y2 = dss1
   END IF
   IF (dssmax .GT. y2) THEN
   min2d = y2d
   min2 = y2
   ELSE
   min2 = dssmax
   min2d = 0.0
   END IF
   dis2d = fis2*(rradd*min2+rrad*min2d)
   dis2 = fis2*rrad*min2
   !dis4 = dim(fis4*rrad, dis2)
   IF (fis4*rrad - dis2 .GT. 0.0) THEN
   dis4d = fis4*rradd - dis2d
   dis4 = fis4*rrad - dis2
   ELSE
   dis4 = 0.0
   dis4d = 0.0
   END IF
   END IF
   !print *,'dis2,4',dis2,dis4
   ! Compute and scatter the dissipative flux.
   ! Density. Store it in the mass flow of the
   ! appropriate sliding mesh interface.
   ddwd = wadjd(ii+1, 0, 0, irho, sps) - wadjd(ii, 0, 0, irho, sps)
   ddw = wadj(ii+1, 0, 0, irho, sps) - wadj(ii, 0, 0, irho, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(ii+2, 0, 0, irho, sps)-&
   &        wadj(ii-1, 0, 0, irho, sps)-three*ddw) - dis4*(wadjd(ii+2, 0, 0&
   &        , irho, sps)-wadjd(ii-1, 0, 0, irho, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(ii+2, 0, 0, irho, sps)-wadj(ii-1, 0, 0&
   &        , irho, sps)-three*ddw)
   !fw(i+1,j,k,irho) = fw(i+1,j,k,irho) + fs
   !fw(i,j,k,irho)   = fw(i,j,k,irho)   - fs
   dwadjd(irho, sps) = dwadjd(irho, sps) + fact*fsd
   dwadj(irho, sps) = dwadj(irho, sps) + fact*fs
   ind = indfamilyi(i, j, k)
   massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(ind, &
   &        spectralsol) - factfamilyi(i, j, k)*fs
   ! X-momentum.
   ddwd = wadjd(ii+1, 0, 0, ivx, sps) - wadjd(ii, 0, 0, ivx, sps)
   ddw = wadj(ii+1, 0, 0, ivx, sps) - wadj(ii, 0, 0, ivx, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(ii+2, 0, 0, ivx, sps)-&
   &        wadj(ii-1, 0, 0, ivx, sps)-three*ddw) - dis4*(wadjd(ii+2, 0, 0, &
   &        ivx, sps)-wadjd(ii-1, 0, 0, ivx, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(ii+2, 0, 0, ivx, sps)-wadj(ii-1, 0, 0, &
   &        ivx, sps)-three*ddw)
   !fw(i+1,j,k,imx) = fw(i+1,j,k,imx) + fs
   !fw(i,j,k,imx)   = fw(i,j,k,imx)   - fs
   dwadjd(imx, sps) = dwadjd(imx, sps) + fact*fsd
   dwadj(imx, sps) = dwadj(imx, sps) + fact*fs
   ! Y-momentum.
   ddwd = wadjd(ii+1, 0, 0, ivy, sps) - wadjd(ii, 0, 0, ivy, sps)
   ddw = wadj(ii+1, 0, 0, ivy, sps) - wadj(ii, 0, 0, ivy, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(ii+2, 0, 0, ivy, sps)-&
   &        wadj(ii-1, 0, 0, ivy, sps)-three*ddw) - dis4*(wadjd(ii+2, 0, 0, &
   &        ivy, sps)-wadjd(ii-1, 0, 0, ivy, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(ii+2, 0, 0, ivy, sps)-wadj(ii-1, 0, 0, &
   &        ivy, sps)-three*ddw)
   !fw(i+1,j,k,imy) = fw(i+1,j,k,imy) + fs
   !fw(i,j,k,imy)   = fw(i,j,k,imy)   - fs
   dwadjd(imy, sps) = dwadjd(imy, sps) + fact*fsd
   dwadj(imy, sps) = dwadj(imy, sps) + fact*fs
   ! Z-momentum.
   ddwd = wadjd(ii+1, 0, 0, ivz, sps) - wadjd(ii, 0, 0, ivz, sps)
   ddw = wadj(ii+1, 0, 0, ivz, sps) - wadj(ii, 0, 0, ivz, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(ii+2, 0, 0, ivz, sps)-&
   &        wadj(ii-1, 0, 0, ivz, sps)-three*ddw) - dis4*(wadjd(ii+2, 0, 0, &
   &        ivz, sps)-wadjd(ii-1, 0, 0, ivz, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(ii+2, 0, 0, ivz, sps)-wadj(ii-1, 0, 0, &
   &        ivz, sps)-three*ddw)
   !fw(i+1,j,k,imz) = fw(i+1,j,k,imz) + fs
   !fw(i,j,k,imz)   = fw(i,j,k,imz)   - fs
   dwadjd(imz, sps) = dwadjd(imz, sps) + fact*fsd
   dwadj(imz, sps) = dwadj(imz, sps) + fact*fs
   ! Energy.
   ddwd = wadjd(ii+1, 0, 0, irhoe, sps) - wadjd(ii, 0, 0, irhoe, sps)
   ddw = wadj(ii+1, 0, 0, irhoe, sps) - wadj(ii, 0, 0, irhoe, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(ii+2, 0, 0, irhoe, sps)-&
   &        wadj(ii-1, 0, 0, irhoe, sps)-three*ddw) - dis4*(wadjd(ii+2, 0, 0&
   &        , irhoe, sps)-wadjd(ii-1, 0, 0, irhoe, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(ii+2, 0, 0, irhoe, sps)-wadj(ii-1, 0, 0&
   &        , irhoe, sps)-three*ddw)
   !fw(i+1,j,k,irhoE) = fw(i+1,j,k,irhoE) + fs
   !fw(i,j,k,irhoE)   = fw(i,j,k,irhoE)   - fs
   dwadjd(irhoe, sps) = dwadjd(irhoe, sps) + fact*fsd
   dwadj(irhoe, sps) = dwadj(irhoe, sps) + fact*fs
   ! Update i and set fact to 1 for the second face.
   i = i + 1
   fact = -one
   END DO
   !!! Set dss1 to dss2 for the next face.
   !!
   !!dss1 = dss2
   !         enddo
   !       enddo
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Dissipative fluxes in the j-direction.                         *
   !      *                                                                *
   !      ******************************************************************
   !
   ! do k=2,kl
   !   do i=2,il
   i = icell
   j = jcell - 1
   k = kcell
   fact = one
   ! Loop over the two faces which contribute to the residual of
   ! the cell considered.
   DO jj=-1,0
   x3d = ((ssd(0, jj+1, 0)-two*ssd(0, jj, 0)+ssd(0, jj-1, 0))*(ss(0, &
   &        jj+1, 0)+two*ss(0, jj, 0)+ss(0, jj-1, 0)+sslim)-(ss(0, jj+1, 0)-&
   &        two*ss(0, jj, 0)+ss(0, jj-1, 0))*(ssd(0, jj+1, 0)+two*ssd(0, jj&
   &        , 0)+ssd(0, jj-1, 0)))/(ss(0, jj+1, 0)+two*ss(0, jj, 0)+ss(0, jj&
   &        -1, 0)+sslim)**2
   x3 = (ss(0, jj+1, 0)-two*ss(0, jj, 0)+ss(0, jj-1, 0))/(ss(0, jj+1&
   &        , 0)+two*ss(0, jj, 0)+ss(0, jj-1, 0)+sslim)
   IF (x3 .GE. 0.) THEN
   dss1d = x3d
   dss1 = x3
   ELSE
   dss1d = -x3d
   dss1 = -x3
   END IF
   x4d = ((ssd(0, jj+2, 0)-two*ssd(0, jj+1, 0)+ssd(0, jj, 0))*(ss(0, &
   &        jj+2, 0)+two*ss(0, jj+1, 0)+ss(0, jj, 0)+sslim)-(ss(0, jj+2, 0)-&
   &        two*ss(0, jj+1, 0)+ss(0, jj, 0))*(ssd(0, jj+2, 0)+two*ssd(0, jj+&
   &        1, 0)+ssd(0, jj, 0)))/(ss(0, jj+2, 0)+two*ss(0, jj+1, 0)+ss(0, &
   &        jj, 0)+sslim)**2
   x4 = (ss(0, jj+2, 0)-two*ss(0, jj+1, 0)+ss(0, jj, 0))/(ss(0, jj+2&
   &        , 0)+two*ss(0, jj+1, 0)+ss(0, jj, 0)+sslim)
   IF (x4 .GE. 0.) THEN
   dss2d = x4d
   dss2 = x4
   ELSE
   dss2d = -x4d
   dss2 = -x4
   END IF
   ! Compute the dissipation coefficients for this face.
   ppor = zero
   IF (porj(i, j, k) .EQ. normalflux) ppor = half
   !rrad = ppor*(radJ(i,j,k) + radJ(i,j+1,k))
   rradd = ppor*(radjadjd(0, jj, 0, sps)+radjadjd(0, jj+1, 0, sps))
   rrad = ppor*(radjadj(0, jj, 0, sps)+radjadj(0, jj+1, 0, sps))
   !lumped Dissipation for preconditioner
   IF (lumpeddiss) THEN
   IF (dss1 .LT. dss2) THEN
   y3d = dss2d
   y3 = dss2
   ELSE
   y3d = dss1d
   y3 = dss1
   END IF
   IF (dssmax .GT. y3) THEN
   min3d = y3d
   min3 = y3
   ELSE
   min3 = dssmax
   min3d = 0.0
   END IF
   dis2d = fis2*(rradd*min3+rrad*min3d) + sigma*fis4*rradd
   dis2 = fis2*rrad*min3 + sigma*fis4*rrad
   dis4 = 0.0
   dis4d = 0.0
   ELSE
   IF (dss1 .LT. dss2) THEN
   y4d = dss2d
   y4 = dss2
   ELSE
   y4d = dss1d
   y4 = dss1
   END IF
   IF (dssmax .GT. y4) THEN
   min4d = y4d
   min4 = y4
   ELSE
   min4 = dssmax
   min4d = 0.0
   END IF
   dis2d = fis2*(rradd*min4+rrad*min4d)
   dis2 = fis2*rrad*min4
   !dis4 = dim(fis4*rrad, dis2)
   IF (fis4*rrad - dis2 .GT. 0.0) THEN
   dis4d = fis4*rradd - dis2d
   dis4 = fis4*rrad - dis2
   ELSE
   dis4 = 0.0
   dis4d = 0.0
   END IF
   END IF
   ! Compute and scatter the dissipative flux.
   ! Density. Store it in the mass flow of the
   ! appropriate sliding mesh interface.
   ddwd = wadjd(0, jj+1, 0, irho, sps) - wadjd(0, jj, 0, irho, sps)
   ddw = wadj(0, jj+1, 0, irho, sps) - wadj(0, jj, 0, irho, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, jj+2, 0, irho, sps)-&
   &        wadj(0, jj-1, 0, irho, sps)-three*ddw) - dis4*(wadjd(0, jj+2, 0&
   &        , irho, sps)-wadjd(0, jj-1, 0, irho, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, jj+2, 0, irho, sps)-wadj(0, jj-1, 0&
   &        , irho, sps)-three*ddw)
   !fw(i,j+1,k,irho) = fw(i,j+1,k,irho) + fs
   !fw(i,j,k,irho)   = fw(i,j,k,irho)   - fs
   dwadjd(irho, sps) = dwadjd(irho, sps) + fact*fsd
   dwadj(irho, sps) = dwadj(irho, sps) + fact*fs
   ind = indfamilyj(i, j, k)
   massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(ind, &
   &        spectralsol) - factfamilyj(i, j, k)*fs
   ! X-momentum.
   ddwd = wadjd(0, jj+1, 0, ivx, sps) - wadjd(0, jj, 0, ivx, sps)
   ddw = wadj(0, jj+1, 0, ivx, sps) - wadj(0, jj, 0, ivx, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, jj+2, 0, ivx, sps)-&
   &        wadj(0, jj-1, 0, ivx, sps)-three*ddw) - dis4*(wadjd(0, jj+2, 0, &
   &        ivx, sps)-wadjd(0, jj-1, 0, ivx, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, jj+2, 0, ivx, sps)-wadj(0, jj-1, 0, &
   &        ivx, sps)-three*ddw)
   !fw(i,j+1,k,imx) = fw(i,j+1,k,imx) + fs
   !fw(i,j,k,imx)   = fw(i,j,k,imx)   - fs
   dwadjd(imx, sps) = dwadjd(imx, sps) + fact*fsd
   dwadj(imx, sps) = dwadj(imx, sps) + fact*fs
   ! Y-momentum.
   ddwd = wadjd(0, jj+1, 0, ivy, sps) - wadjd(0, jj, 0, ivy, sps)
   ddw = wadj(0, jj+1, 0, ivy, sps) - wadj(0, jj, 0, ivy, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, jj+2, 0, ivy, sps)-&
   &        wadj(0, jj-1, 0, ivy, sps)-three*ddw) - dis4*(wadjd(0, jj+2, 0, &
   &        ivy, sps)-wadjd(0, jj-1, 0, ivy, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, jj+2, 0, ivy, sps)-wadj(0, jj-1, 0, &
   &        ivy, sps)-three*ddw)
   !fw(i,j+1,k,imy) = fw(i,j+1,k,imy) + fs
   !fw(i,j,k,imy)   = fw(i,j,k,imy)   - fs
   dwadjd(imy, sps) = dwadjd(imy, sps) + fact*fsd
   dwadj(imy, sps) = dwadj(imy, sps) + fact*fs
   ! Z-momentum.
   ddwd = wadjd(0, jj+1, 0, ivz, sps) - wadjd(0, jj, 0, ivz, sps)
   ddw = wadj(0, jj+1, 0, ivz, sps) - wadj(0, jj, 0, ivz, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, jj+2, 0, ivz, sps)-&
   &        wadj(0, jj-1, 0, ivz, sps)-three*ddw) - dis4*(wadjd(0, jj+2, 0, &
   &        ivz, sps)-wadjd(0, jj-1, 0, ivz, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, jj+2, 0, ivz, sps)-wadj(0, jj-1, 0, &
   &        ivz, sps)-three*ddw)
   !fw(i,j+1,k,imz) = fw(i,j+1,k,imz) + fs
   !fw(i,j,k,imz)   = fw(i,j,k,imz)   - fs
   dwadjd(imz, sps) = dwadjd(imz, sps) + fact*fsd
   dwadj(imz, sps) = dwadj(imz, sps) + fact*fs
   ! Energy.
   ddwd = wadjd(0, jj+1, 0, irhoe, sps) - wadjd(0, jj, 0, irhoe, sps)
   ddw = wadj(0, jj+1, 0, irhoe, sps) - wadj(0, jj, 0, irhoe, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, jj+2, 0, irhoe, sps)-&
   &        wadj(0, jj-1, 0, irhoe, sps)-three*ddw) - dis4*(wadjd(0, jj+2, 0&
   &        , irhoe, sps)-wadjd(0, jj-1, 0, irhoe, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, jj+2, 0, irhoe, sps)-wadj(0, jj-1, 0&
   &        , irhoe, sps)-three*ddw)
   !fw(i,j+1,k,irhoE) = fw(i,j+1,k,irhoE) + fs
   !fw(i,j,k,irhoE)   = fw(i,j,k,irhoE)   - fs
   dwadjd(irhoe, sps) = dwadjd(irhoe, sps) + fact*fsd
   dwadj(irhoe, sps) = dwadj(irhoe, sps) + fact*fs
   ! Update j and set fact to 1 for the second face.
   j = j + 1
   fact = -one
   END DO
   !!! Set dss1 to dss2 for the next face.
   !!
   !!dss1 = dss2
   !enddo
   !enddo
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Dissipative fluxes in the k-direction.                         *
   !      *                                                                *
   !      ******************************************************************
   !    
   ! Fluxes in k-direction.
   i = icell
   j = jcell
   k = kcell - 1
   fact = one
   !       do j=2,jl
   !         do i=2,il
   ! Loop over the two faces which contribute to the residual of
   ! the cell considered.
   DO kk=-1,0
   x5d = ((ssd(0, 0, kk+1)-two*ssd(0, 0, kk)+ssd(0, 0, kk-1))*(ss(0, &
   &        0, kk+1)+two*ss(0, 0, kk)+ss(0, 0, kk-1)+sslim)-(ss(0, 0, kk+1)-&
   &        two*ss(0, 0, kk)+ss(0, 0, kk-1))*(ssd(0, 0, kk+1)+two*ssd(0, 0, &
   &        kk)+ssd(0, 0, kk-1)))/(ss(0, 0, kk+1)+two*ss(0, 0, kk)+ss(0, 0, &
   &        kk-1)+sslim)**2
   x5 = (ss(0, 0, kk+1)-two*ss(0, 0, kk)+ss(0, 0, kk-1))/(ss(0, 0, kk&
   &        +1)+two*ss(0, 0, kk)+ss(0, 0, kk-1)+sslim)
   IF (x5 .GE. 0.) THEN
   dss1d = x5d
   dss1 = x5
   ELSE
   dss1d = -x5d
   dss1 = -x5
   END IF
   x6d = ((ssd(0, 0, kk+2)-two*ssd(0, 0, kk+1)+ssd(0, 0, kk))*(ss(0, &
   &        0, kk+2)+two*ss(0, 0, kk+1)+ss(0, 0, kk)+sslim)-(ss(0, 0, kk+2)-&
   &        two*ss(0, 0, kk+1)+ss(0, 0, kk))*(ssd(0, 0, kk+2)+two*ssd(0, 0, &
   &        kk+1)+ssd(0, 0, kk)))/(ss(0, 0, kk+2)+two*ss(0, 0, kk+1)+ss(0, 0&
   &        , kk)+sslim)**2
   x6 = (ss(0, 0, kk+2)-two*ss(0, 0, kk+1)+ss(0, 0, kk))/(ss(0, 0, kk&
   &        +2)+two*ss(0, 0, kk+1)+ss(0, 0, kk)+sslim)
   IF (x6 .GE. 0.) THEN
   dss2d = x6d
   dss2 = x6
   ELSE
   dss2d = -x6d
   dss2 = -x6
   END IF
   ! Compute the dissipation coefficients for this face.
   ppor = zero
   IF (pork(i, j, k) .EQ. normalflux) ppor = half
   !rrad = ppor*(radK(i,j,k) + radK(i,j,k+1))
   rradd = ppor*(radkadjd(0, 0, kk, sps)+radkadjd(0, 0, kk+1, sps))
   rrad = ppor*(radkadj(0, 0, kk, sps)+radkadj(0, 0, kk+1, sps))
   !lumped Dissipation for preconditioner
   IF (lumpeddiss) THEN
   IF (dss1 .LT. dss2) THEN
   y5d = dss2d
   y5 = dss2
   ELSE
   y5d = dss1d
   y5 = dss1
   END IF
   IF (dssmax .GT. y5) THEN
   min5d = y5d
   min5 = y5
   ELSE
   min5 = dssmax
   min5d = 0.0
   END IF
   dis2d = fis2*(rradd*min5+rrad*min5d) + sigma*fis4*rradd
   dis2 = fis2*rrad*min5 + sigma*fis4*rrad
   dis4 = 0.0
   dis4d = 0.0
   ELSE
   IF (dss1 .LT. dss2) THEN
   y6d = dss2d
   y6 = dss2
   ELSE
   y6d = dss1d
   y6 = dss1
   END IF
   IF (dssmax .GT. y6) THEN
   min6d = y6d
   min6 = y6
   ELSE
   min6 = dssmax
   min6d = 0.0
   END IF
   dis2d = fis2*(rradd*min6+rrad*min6d)
   dis2 = fis2*rrad*min6
   !dis4 = dim(fis4*rrad, dis2)
   IF (fis4*rrad - dis2 .GT. 0.0) THEN
   dis4d = fis4*rradd - dis2d
   dis4 = fis4*rrad - dis2
   ELSE
   dis4 = 0.0
   dis4d = 0.0
   END IF
   END IF
   ! Compute and scatter the dissipative flux.
   ! Density. Store it in the mass flow of the
   ! appropriate sliding mesh interface.
   ddwd = wadjd(0, 0, kk+1, irho, sps) - wadjd(0, 0, kk, irho, sps)
   ddw = wadj(0, 0, kk+1, irho, sps) - wadj(0, 0, kk, irho, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, 0, kk+2, irho, sps)-&
   &        wadj(0, 0, kk-1, irho, sps)-three*ddw) - dis4*(wadjd(0, 0, kk+2&
   &        , irho, sps)-wadjd(0, 0, kk-1, irho, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, 0, kk+2, irho, sps)-wadj(0, 0, kk-1&
   &        , irho, sps)-three*ddw)
   !fw(i,j,k+1,irho) = fw(i,j,k+1,irho) + fs
   !fw(i,j,k,irho)   = fw(i,j,k,irho)   - fs
   dwadjd(irho, sps) = dwadjd(irho, sps) + fact*fsd
   dwadj(irho, sps) = dwadj(irho, sps) + fact*fs
   ind = indfamilyk(i, j, k)
   massflowfamilydiss(ind, spectralsol) = massflowfamilydiss(ind, &
   &        spectralsol) - factfamilyk(i, j, k)*fs
   ! X-momentum.
   ddwd = wadjd(0, 0, kk+1, ivx, sps) - wadjd(0, 0, kk, ivx, sps)
   ddw = wadj(0, 0, kk+1, ivx, sps) - wadj(0, 0, kk, ivx, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, 0, kk+2, ivx, sps)-&
   &        wadj(0, 0, kk-1, ivx, sps)-three*ddw) - dis4*(wadjd(0, 0, kk+2, &
   &        ivx, sps)-wadjd(0, 0, kk-1, ivx, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, 0, kk+2, ivx, sps)-wadj(0, 0, kk-1, &
   &        ivx, sps)-three*ddw)
   !fw(i,j,k+1,imx) = fw(i,j,k+1,imx) + fs
   !fw(i,j,k,imx)   = fw(i,j,k,imx)   - fs
   dwadjd(imx, sps) = dwadjd(imx, sps) + fact*fsd
   dwadj(imx, sps) = dwadj(imx, sps) + fact*fs
   ! Y-momentum.
   ddwd = wadjd(0, 0, kk+1, ivy, sps) - wadjd(0, 0, kk, ivy, sps)
   ddw = wadj(0, 0, kk+1, ivy, sps) - wadj(0, 0, kk, ivy, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, 0, kk+2, ivy, sps)-&
   &        wadj(0, 0, kk-1, ivy, sps)-three*ddw) - dis4*(wadjd(0, 0, kk+2, &
   &        ivy, sps)-wadjd(0, 0, kk-1, ivy, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, 0, kk+2, ivy, sps)-wadj(0, 0, kk-1, &
   &        ivy, sps)-three*ddw)
   !fw(i,j,k+1,imy) = fw(i,j,k+1,imy) + fs
   !fw(i,j,k,imy)   = fw(i,j,k,imy)   - fs
   dwadjd(imy, sps) = dwadjd(imy, sps) + fact*fsd
   dwadj(imy, sps) = dwadj(imy, sps) + fact*fs
   ! Z-momentum.
   ddwd = wadjd(0, 0, kk+1, ivz, sps) - wadjd(0, 0, kk, ivz, sps)
   ddw = wadj(0, 0, kk+1, ivz, sps) - wadj(0, 0, kk, ivz, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, 0, kk+2, ivz, sps)-&
   &        wadj(0, 0, kk-1, ivz, sps)-three*ddw) - dis4*(wadjd(0, 0, kk+2, &
   &        ivz, sps)-wadjd(0, 0, kk-1, ivz, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, 0, kk+2, ivz, sps)-wadj(0, 0, kk-1, &
   &        ivz, sps)-three*ddw)
   !fw(i,j,k+1,imz) = fw(i,j,k+1,imz) + fs
   !fw(i,j,k,imz)   = fw(i,j,k,imz)   - fs
   dwadjd(imz, sps) = dwadjd(imz, sps) + fact*fsd
   dwadj(imz, sps) = dwadj(imz, sps) + fact*fs
   ! Energy.
   ddwd = wadjd(0, 0, kk+1, irhoe, sps) - wadjd(0, 0, kk, irhoe, sps)
   ddw = wadj(0, 0, kk+1, irhoe, sps) - wadj(0, 0, kk, irhoe, sps)
   fsd = dis2d*ddw + dis2*ddwd - dis4d*(wadj(0, 0, kk+2, irhoe, sps)-&
   &        wadj(0, 0, kk-1, irhoe, sps)-three*ddw) - dis4*(wadjd(0, 0, kk+2&
   &        , irhoe, sps)-wadjd(0, 0, kk-1, irhoe, sps)-three*ddwd)
   fs = dis2*ddw - dis4*(wadj(0, 0, kk+2, irhoe, sps)-wadj(0, 0, kk-1&
   &        , irhoe, sps)-three*ddw)
   !fw(i,j,k+1,irhoE) = fw(i,j,k+1,irhoE) + fs
   !fw(i,j,k,irhoE)   = fw(i,j,k,irhoE)   - fs
   dwadjd(irhoe, sps) = dwadjd(irhoe, sps) + fact*fsd
   dwadj(irhoe, sps) = dwadj(irhoe, sps) + fact*fs
   ! Update k and set fact to 1 for the second face.
   k = k + 1
   fact = -one
   END DO
   !!! Set dss1 to dss2 for the next face.
   !!
   !dss1 = dss2
   !enddo
   !enddo
   ! Replace rho times the total enthalpy by the total energy and
   ! store the velocities again instead of the momentum. Only for
   ! those entries that have been altered, i.e. ignore the
   ! corner halo's.
   ! Again, do we need to ignore the halo's? Simpler if we just 
   ! copy everything....
   !0,kb
   DO k=-2,2
   !2,jl
   DO j=-2,2
   !2,il
   DO i=-2,2
   rhoid = -(one*wadjd(i, j, k, irho, sps)/wadj(i, j, k, irho, &
   &            sps)**2)
   rhoi = one/wadj(i, j, k, irho, sps)
   wadjd(i, j, k, ivx, sps) = wadjd(i, j, k, ivx, sps)*rhoi + &
   &            wadj(i, j, k, ivx, sps)*rhoid
   wadj(i, j, k, ivx, sps) = wadj(i, j, k, ivx, sps)*rhoi
   wadjd(i, j, k, ivy, sps) = wadjd(i, j, k, ivy, sps)*rhoi + &
   &            wadj(i, j, k, ivy, sps)*rhoid
   wadj(i, j, k, ivy, sps) = wadj(i, j, k, ivy, sps)*rhoi
   wadjd(i, j, k, ivz, sps) = wadjd(i, j, k, ivz, sps)*rhoi + &
   &            wadj(i, j, k, ivz, sps)*rhoid
   wadj(i, j, k, ivz, sps) = wadj(i, j, k, ivz, sps)*rhoi
   wadjd(i, j, k, irhoe, sps) = wadjd(i, j, k, irhoe, sps) - &
   &            padjd(i, j, k, sps)
   wadj(i, j, k, irhoe, sps) = wadj(i, j, k, irhoe, sps) - padj(i&
   &            , j, k, sps)
   END DO
   END DO
   END DO
   END IF
   END SUBROUTINE INVISCIDDISSFLUXSCALARNKPC_D