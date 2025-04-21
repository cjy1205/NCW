!****************************************************************************!
!   正压原始方程模式
!   1985 10 29 by  Shen tongli
!   m=20 为x方向格点数，n=16 为y方向格点数，d为网格距，rm为放大系数
!   f为地转参数，w为工作数组，cla，clo分别为区域中心纬度和经度
!   dt为时间步长，s为平滑系数
!   ua，ub，uc分别为n-1，n，n+1时间层的x方向风速
!   va，vb，vc分别为n-1，n，n+1时间层的y方向风速
!   za，zb，zc分别为n-1，n，n+1时间层的位势高度
!   na用于控制12小时的预报；nb用于记录时间积分步数；nt2=72用于判别
!   是否积分12小时，是否该做内点平滑；nt4=6用于判定是否该做边界平滑；
!   nt5用于判定是否该做时间平滑。 
!   zo是为了减小重力惯性外波的波速，增加差分格式的稳定性而引入的位势高度。     
!****************************************************************************!
    
    program shen2
        parameter(m=20,n=16,d=300000.0,cla=51.0,clo=118.0,dt=600.0)
        dimension ua(m,n),va(m,n),za(m,n),ub(m,n),vb(m,n),zb(m,n),    &
                 uc(m,n),vc(m,n),zc(m,n),rm(m,n),f(m,n),w(m,n)
        integer*4 access, status
        real zo, s, c1, c2
        integer nt2, nt4, nt5, use_three_step, use_ts,use_ssip,use_ssbp,l
        character(len=20) :: zc_filename, uc_filename, vc_filename

        zo = 2500.0 ! 为了减小重力惯性外波的波速，增加差分格式的稳定性而引入的位势高度
        s = 0.5
        nt2 = 72
        nt4 = 6
        nt5 = 36
        c1 = dt / 2.0
        c2 = dt * 2.0
        use_ts = 1  ! 1表示使用时间平滑，0表示不使用时间平滑
        l = 2  ! 1表示正平滑，2表示正逆平滑
        use_three_step = 1 ! 1表示使用三步积分法，0表示使用中央差
        use_ssip = 1 ! 1表示使用区域内点平滑，0表示不使用区域内点平滑
        use_ssbp = 1 ! 1表示使用边界平滑，0表示不使用边界平滑
        zc_filename = 'zc_nots_b.dat' !
        uc_filename = 'uc_nots_b.dat'
        vc_filename = 'vc_nots_b.dat'
    !   检查是否存在h.grd,rm.dat,f.dat等文件，若存在则先删除
        status = access('h.grd', ' ')
        if ( status .eq. 0 ) then
            call system('del h.grd')
            call system('del rm.dat')       
            call system('del f.dat')         
            call system('del '//zc_filename)
            call system('del '//uc_filename)       
            call system('del '//vc_filename)   
        end if
        
    !   为便于Grads做图而建立的位势高度场数据文件h.grd（包括初始场和预报场）    
        open(10,file='h.grd',form='unformatted')     
        
    !   计算放大系数和地转参数,并写入数据文件中
        call cmf(rm,f,d,cla,m,n)
        open(1,file='rm.dat',status='new')
        write(1,101) rm
        close(1)
    101 format(20f10.5)
        
        open(1,file='f.dat',status='new')
        write(1,103) f
        close(1)
    103 format(20e15.5)
    
    !   读入初始资料场 
        open(2,file='za.dat',status='old')
        read(2,102) za 
        close(2)
    102 format(20f6.0)        
        
    !************************加入地转风子程序后此处需要修改************************!
    !   计算地转风初值   
    !   call cgw(ua,va,za,rm,f,d,m,n)
    !   open(4,file='ua.dat',status='new')
    !   write(4,104) ua
    !   close(4)
    !   open(5,file='va.dat',status='new')
    !   write(5,104) va
    !   close(5)
        open(4,file='ua.dat',status='old')
        read(4,104) ua
        close(4)
        open(5,file='va.dat',status='old')
        read(5,104) va
        close(5)
    104 format(20f10.5)
    !******************************************************************************!
        
    !   边值传送子程序
        call tbv(ub,vb,zb,ua,va,za,m,n)
        call tbv(uc,vc,zc,ua,va,za,m,n)  
    !   开始预报  
        do na=1,2
            nb=0
    !   欧拉后差积分1小时
            do nn=1,6
                call ti(ua,va,za,ua,va,za,ub,vb,zb,rm,f,d,dt,zo,m,n)
                call ti(ua,va,za,ub,vb,zb,ua,va,za,rm,f,d,dt,zo,m,n)
                nb=nb+1
            end do
            
    !   边界平滑子程序
            call ssbp(za,w,s,m,n)
            call ssbp(ua,w,s,m,n)
            call ssbp(va,w,s,m,n)
    
        !   前差积分半步
            if (use_three_step==1) then
                call ti(ua,va,za,ua,va,za,ub,vb,zb,rm,f,d,c1,zo,m,n)
        !   中央差积分半步
                call ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,dt,zo,m,n)
                nb=nb+1
                        
        !   数组传送子程序
                call ta(ub,vb,zb,uc,vc,zc,m,n)
            end if

        
    !   中央差积分一步,共积分11小时
            do nn=1,66
                call ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,c2,zo,m,n)
                nb=nb+1
    !   打印积分步数,na大循环步,nb小循环步
                call pv(na,nb)
    !   判断是否积分12小时
                if(nb.eq.nt2) go to 80
    !   判断是否做边界平滑
                if(nb/nt4*nt4.eq.nb .and. use_ssip==1) go to 40
                go to 50
    40          call ssbp(zc,w,s,m,n)
                call ssbp(uc,w,s,m,n)
                call ssbp(vc,w,s,m,n)        
    
    !   判断是否做时间平滑
                if(use_ts==1) go to 50
                go to 70
    50          if(nb.eq.nt5) go to 60
                if(nb.eq.nt5+1) go to 60
                go to 70
    !   时间平滑子程序
    60          call ts(ua,ub,uc,va,vb,vc,za,zb,zc,s,m,n)
    
    !   数组传送,为下一轮积分做准备
    70          call ta(ua,va,za,ub,vb,zb,m,n)
                call ta(ub,vb,zb,uc,vc,zc,m,n)
            end do
    
    !   区域内点平滑
    80      call ssip(zc,w,s,m,n,l) ! 2正逆平滑,1正平滑
            call ssip(uc,w,s,m,n,l)
            call ssip(vc,w,s,m,n,l)
       
    !   打印积分步数
            call pv(na,nb)   
            
    !   数组传送,为后12小时的积分做准备
            call ta(ua,va,za,uc,vc,zc,m,n)
        end do
        
    !   存放预报结果
        open(6, file=zc_filename, status='new')
        write(6, 102) zc
        close(6)
        write(10) ((zc(i, j), i=1, m), j=1, n)

        open(7, file=uc_filename, status='new')
        write(7, 104) uc
        close(7)

        open(8, file=vc_filename, status='new')
        write(8, 104) vc
        close(8)
        stop
        end program shen2
        
        
    !   computing map factors and coriolis parameter
    !   rk为圆锥常数,rlq为兰勃特投影映像平面上赤道到北极点的距离,a为地球半径
    !   sita为标准余纬,psx为区域中心余纬,r为模式中心到北极的距离
        subroutine cmf(rm,f,d,cla,m,n)
        dimension rm(m,n),f(m,n)
        rk=0.7156
        rlq=11423370.0
        a=6371000.0
        conv=57.29578
        w1=2.0/rk
        sita=30.0/conv
        psx=(90.0-cla)/conv
    
    !   计算模式中心到北极的距离r 
        cel0=a*sin(sita)/rk
        cel=(tan(psx/2.0))/(tan(sita/2.0))
        r=cel0*cel**rk
    
    !   确定网格坐标原点在地图坐标系中的位置
        xi0=-(m-1)/2.0
        yj0=r/d+(n-1)/2.0
    
    !   求各格点至北极点的距离rl,(xj,yi)为模式各格点在地图坐标系中的位置  
        do i=1,m
            do j=1,n
                xi=xi0+(i-1)
                yj=yj0-(j-1)
                rl=sqrt(xi**2+yj**2)*d
    
                !   求放大系数rm和柯氏参数f
                w2=(rl/rlq)**w1
                sinl=(1.0-w2)/(1.0+w2)
                rm(i,j)=rk*rl/(a*sqrt(1.0-sinl**2))
                f(i,j)=1.4584e-4*sinl
            end do
        end do
        return
        end    
        
    !   transmiting boundary valaus  赋固定边界值
        subroutine tbv(ua,va,za,ub,vb,zb,m,n)
        dimension ua(m,n),va(m,n),za(m,n),ub(m,n),vb(m,n),zb(m,n)
        m1=m-1
        n1=n-1
        do i=1,m
            do j=1,n,n1
                ua(i,j)=ub(i,j)
                va(i,j)=vb(i,j)
                za(i,j)=zb(i,j)
            end do
        end do
        do i=1,m,m1
            do j=1,n
                ua(i,j)=ub(i,j)
                va(i,j)=vb(i,j)
                za(i,j)=zb(i,j)
            end do
        end do
        return
        end
    
        
    !************************需要进行编写************************！
    !   time integrations  
        subroutine ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,dt,zo,m,n)
        dimension ua(m,n),va(m,n),za(m,n),ub(m,n),vb(m,n),zb(m,n),uc(m,n),vc(m,n),zc(m,n),rm(m,n),f(m,n)
        m1=m-1
        n1=n-1
        g = 9.8
        do i=2,m1
        do j=2,n1
                u_term1 = (ub(i+1,j)+ub(i,j))*(ub(i+1,j)-ub(i,j))+(ub(i,j)+ub(i-1,j))*(ub(i,j)-ub(i-1,j))
                u_term2 = (vb(i,j-1)+vb(i,j))*(ub(i,j)-ub(i,j-1))+(vb(i,j)+vb(i,j+1))*(ub(i,j+1)-ub(i,j))
                u_term3 = 2*g*(zb(i+1,j)-zb(i-1,j))
                u_term4 = (2*d*f(i,j)+ub(i,j)*(rm(i,j+1)-rm(i,j-1))+vb(i,j)*(rm(i+1,j)-rm(i-1,j)))*vb(i,j) / (2*d)
                u_right_term = (-rm(i,j)*(u_term1+u_term2+u_term3))/(4*d)+u_term4
                uc(i,j)=ua(i,j)+u_right_term*dt
        enddo
        enddo
        do i=2,m1
            do j=2,n1
                v_term1 = (ub(i+1,j)+ub(i,j))*(vb(i+1,j)-vb(i,j))+(ub(i,j)+ub(i-1,j))*(vb(i,j)-vb(i-1,j))
                v_term2 = (vb(i,j-1)+vb(i,j))*(vb(i,j)-vb(i,j-1))+(vb(i,j)+vb(i,j+1))*(vb(i,j+1)-vb(i,j))
                v_term3 = 2*g*(zb(i,j+1)-zb(i,j-1))
                v_term4 = -(2*d*f(i,j)+ub(i,j)*(rm(i,j+1)-rm(i,j-1))+vb(i,j)*(rm(i+1,j)-rm(i-1,j)))*ub(i,j) / (2*d)
                v_right_term = (-rm(i,j)*(v_term1+v_term2+v_term3))/(4*d)+v_term4
                vc(i,j)=va(i,j)+v_right_term*dt
        enddo
        enddo
        do i=2,m1
            do j=2,n1
                z_term1 = ((ub(i+1,j)+ub(i,j))*(zb(i+1,j)-zb(i,j))+(ub(i,j)+ub(i-1,j))*(zb(i,j)-zb(i-1,j)))/(4*d)
                z_term2 = ((vb(i,j-1)+vb(i,j))*(zb(i,j)-zb(i,j-1))+(vb(i,j)+vb(i,j+1))*(zb(i,j+1)-zb(i,j)))/(4*d)
                z_term3 = (zb(i,j)-zo)*(ub(i+1,j)-ub(i-1,j)+vb(i,j+1)-vb(i,j-1))/(2*d)
                z_right_term = -rm(i,j)*(z_term1+z_term2+z_term3)
                zc(i,j)=za(i,j)+z_right_term*dt
            enddo
        enddo
        return
        end
  
    !************************************************************！
    
    !   space smoothing for boundary points 边界九点平滑
        subroutine ssbp(a,w,s,m,n)
        dimension a(m,n),w(m,n)
        m1=m-1
        m3=m-3
        n1=n-1
        n2=n-2
        n3=n-3
        do i=2,m1
            do j=2,n1,n3
                w(i,j)=a(i,j)+0.5*s*(1.0-s)*                                        &
                    (a(i-1,j)+a(i+1,j)+a(i,j-1)+a(i,j+1)-4.0*a(i,j))+0.25*s*s*      &
                    (a(i-1,j-1)+a(i-1,j+1)+a(i+1,j-1)+a(i+1,j+1)-4.0*a(i,j))
            end do
        end do
        do i=2,m1,m3
            do j=3,n2
                w(i,j)=a(i,j)+0.5*s*(1.0-s)*                                        &
                    (a(i-1,j)+a(i+1,j)+a(i,j-1)+a(i,j+1)-4.0*a(i,j))+0.25*s*s*      &
                    (a(i-1,j-1)+a(i-1,j+1)+a(i+1,j-1)+a(i+1,j+1)-4.0*a(i,j))
            end do    
        end do
        do i=2,m1
            do j=2,n1,n3
                a(i,j)=w(i,j)
            end do
        end do
        do i=2,m1,m3
            do j=3,n2
                a(i,j)=w(i,j)
            end do
        end do
        return  
        end
        
    !   transmiting arrays  数组传送
        subroutine ta(ua,va,za,ub,vb,zb,m,n)
        dimension ua(m,n),va(m,n),za(m,n),ub(m,n),vb(m,n),zb(m,n)
        do i=1,m
            do j=1,n
                ua(i,j)=ub(i,j)
                va(i,j)=vb(i,j)
                za(i,j)=zb(i,j)
            end do
        end do
        return
        end    
    
    !   printing variables  打印积分步数
        subroutine pv(na,nb)
        write(*,100) na,nb
    100 format(5x,3hna=,i3,5x,3hnb=,i2/)
        return
        end 
        
    
    !************************需要进行编写************************！
    !   space smoothing for internal points 区域内5点平滑(正逆平滑)
    !   可选做正逆平滑或正平滑   l=1为只执行正平滑，l=2为执行正逆平滑.
    !************************************************************！
        subroutine ssip(a,w,s,m,n,l)
        dimension a(m,n),w(m,n)
            m1=m-1
            n1=n-1        
            do i=2,m1       
                do j=2,n1       
                    w(i,j)=a(i,j)+s*0.25*(a(i+1,j)+a(i,j+1)+a(i-1,j)+a(i,j-1)-4*a(i,j)) !正平滑
                end do
            end do
            do i=2,m1  
                do j=2,n1   
                    a(i,j)=w(i,j) 
                enddo 
            enddo   
            if(l==2)then  !执行完正平滑后执行逆平滑
                do i=2,m1   
                    do j=2,n1 
                        w(i,j)=a(i,j)+(-s)*0.25*(a(i-1,j)+a(i+1,j)+a(i,j-1)+a(i,j+1)-4*a(i,j)) !逆平滑
                    end do
                end do
                do i=2,m1  
                    do j=2,n1   
                        a(i,j)=w(i,j) 
                    enddo 
                enddo
            endif
            return
        end 
    !   time smoothimg
        subroutine ts(ua,ub,uc,va,vb,vc,za,zb,zc,s,m,n)
        dimension ua(m,n),va(m,n),za(m,n),                          &
                 ub(m,n),vb(m,n),zb(m,n),                            &
                 uc(m,n),vc(m,n),zc(m,n)
        m1=m-1
        n1=n-1
        do i=2,m1
            do j=2,n1
                ub(i,j)=ub(i,j)+s*(ua(i,j)+uc(i,j)-2.0*ub(i,j))/2.0
                vb(i,j)=vb(i,j)+s*(va(i,j)+vc(i,j)-2.0*vb(i,j))/2.0
                zb(i,j)=zb(i,j)+s*(za(i,j)+zc(i,j)-2.0*zb(i,j))/2.0
            end do
        end do
        return
        end    
        