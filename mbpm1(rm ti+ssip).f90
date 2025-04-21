!****************************************************************************!
!   ��ѹԭʼ����ģʽ
!   1985 10 29 by  Shen tongli
!   m=20 Ϊx����������n=16 Ϊy����������dΪ����࣬rmΪ�Ŵ�ϵ��
!   fΪ��ת������wΪ�������飬cla��clo�ֱ�Ϊ��������γ�Ⱥ;���
!   dtΪʱ�䲽����sΪƽ��ϵ��
!   ua��ub��uc�ֱ�Ϊn-1��n��n+1ʱ����x�������
!   va��vb��vc�ֱ�Ϊn-1��n��n+1ʱ����y�������
!   za��zb��zc�ֱ�Ϊn-1��n��n+1ʱ����λ�Ƹ߶�
!   na���ڿ���12Сʱ��Ԥ����nb���ڼ�¼ʱ����ֲ�����nt2=72�����б�
!   �Ƿ����12Сʱ���Ƿ�����ڵ�ƽ����nt4=6�����ж��Ƿ�����߽�ƽ����
!   nt5�����ж��Ƿ����ʱ��ƽ���� 
!   zo��Ϊ�˼�С���������Ⲩ�Ĳ��٣����Ӳ�ָ�ʽ���ȶ��Զ������λ�Ƹ߶ȡ�     
!****************************************************************************!
    
    program shen2
    parameter(m=20,n=16,d=300000.0,cla=51.0,clo=118.0,dt=600.0)
    dimension ua(m,n),va(m,n),za(m,n),ub(m,n),vb(m,n),zb(m,n),    &
     		uc(m,n),vc(m,n),zc(m,n),rm(m,n),f(m,n),w(m,n)
    integer*4 access,status
    zo=2500.0
    s=0.5
    nt2=72
    nt4=6
    nt5=36
    c1=dt/2.0
    c2=dt*2.0
    
!   ����Ƿ����h.grd,rm.dat,f.dat���ļ�������������ɾ��
    status = access('h.grd', ' ')
    if ( status .eq. 0 ) then
        call system('del h.grd')
        call system('del rm.dat')       
        call system('del f.dat')         
        call system('del zc.dat')
        call system('del uc.dat')       
        call system('del vc.dat')   
    end if
    
!   Ϊ����Grads��ͼ��������λ�Ƹ߶ȳ������ļ�h.grd��������ʼ����Ԥ������    
    open(10,file='h.grd',form='unformatted')     
    
!   ����Ŵ�ϵ���͵�ת����,��д�������ļ���
    call cmf(rm,f,d,cla,m,n)
    open(1,file='rm.dat',status='new')
    write(1,101) rm
    close(1)
101 format(20f10.5)
    
    open(1,file='f.dat',status='new')
    write(1,103) f
    close(1)
103 format(20e15.5)

!   �����ʼ���ϳ� 
    open(2,file='za.dat',status='old')
    read(2,102) za 
    close(2)
102 format(20f6.0)        
    
!************************�����ת���ӳ����˴���Ҫ�޸�************************!
!   �����ת���ֵ   
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
    
!   ��ֵ�����ӳ���
    call tbv(ub,vb,zb,ua,va,za,m,n)
    call tbv(uc,vc,zc,ua,va,za,m,n)  
!   ��ʼԤ��  
    do na=1,2
        nb=0
!   ŷ��������1Сʱ
        do nn=1,6
            call ti(ua,va,za,ua,va,za,ub,vb,zb,rm,f,d,dt,zo,m,n)
            call ti(ua,va,za,ub,vb,zb,ua,va,za,rm,f,d,dt,zo,m,n)
            nb=nb+1
        end do
        
!   �߽�ƽ���ӳ���
        call ssbp(za,w,s,m,n)
        call ssbp(ua,w,s,m,n)
        call ssbp(va,w,s,m,n)

!   ǰ����ְ벽
        call ti(ua,va,za,ua,va,za,ub,vb,zb,rm,f,d,c1,zo,m,n)
!   �������ְ벽
        call ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,dt,zo,m,n)
        nb=nb+1        
    
!   ���鴫���ӳ���
        call ta(ub,vb,zb,uc,vc,zc,m,n)
    
!   ��������һ��,������11Сʱ
        do nn=1,66
            call ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,c2,zo,m,n)
            nb=nb+1
!   ��ӡ���ֲ���,na��ѭ����,nbСѭ����
            call pv(na,nb)
!   �ж��Ƿ����12Сʱ
            if(nb.eq.nt2) go to 80
!   �ж��Ƿ����߽�ƽ��
            if(nb/nt4*nt4.eq.nb) go to 40
            go to 50
40          call ssbp(zc,w,s,m,n)
            call ssbp(uc,w,s,m,n)
            call ssbp(vc,w,s,m,n)        

!   �ж��Ƿ���ʱ��ƽ��
50          if(nb.eq.nt5) go to 60
            if(nb.eq.nt5+1) go to 60
            go to 70
!   ʱ��ƽ���ӳ���
60          call ts(ua,ub,uc,va,vb,vc,za,zb,zc,s,m,n)

!   ���鴫��,Ϊ��һ�ֻ�����׼��
70          call ta(ua,va,za,ub,vb,zb,m,n)
            call ta(ub,vb,zb,uc,vc,zc,m,n)
        end do

!   �����ڵ�ƽ��
80      call ssip(zc,w,s,m,n,2)
        call ssip(uc,w,s,m,n,2)
        call ssip(vc,w,s,m,n,2)
   
!   ��ӡ���ֲ���
        call pv(na,nb)   
        
!   ���鴫��,Ϊ��12Сʱ�Ļ�����׼��
        call ta(ua,va,za,uc,vc,zc,m,n)
    end do
    
!   ���Ԥ�����
    open(6,file='zc.dat',status='new')
    write(6,102) zc
    close(6)
    write(10) ((zc(i,j),i=1,m),j=1,n)    
    open(7,file='uc.dat',status='new')
    write(7,104) uc
    close(7)
    open(8,file='vc.dat',status='new')
    write(8,104) vc
    close(8)
    stop
    end program shen2
    
    
!   computing map factors and coriolis parameter
!   rkΪԲ׶����,rlqΪ������ͶӰӳ��ƽ���ϳ����������ľ���,aΪ����뾶
!   sitaΪ��׼��γ,psxΪ����������γ,rΪģʽ���ĵ������ľ���
    subroutine cmf(rm,f,d,cla,m,n)
    dimension rm(m,n),f(m,n)
    rk=0.7156
    rlq=11423370.0
    a=6371000.0
    conv=57.29578
    w1=2.0/rk
    sita=30.0/conv
    psx=(90.0-cla)/conv

!   ����ģʽ���ĵ������ľ���r 
    cel0=a*sin(sita)/rk
    cel=(tan(psx/2.0))/(tan(sita/2.0))
    r=cel0*cel**rk

!   ȷ����������ԭ���ڵ�ͼ����ϵ�е�λ��
    xi0=-(m-1)/2.0
    yj0=r/d+(n-1)/2.0

!   ��������������ľ���rl,(xj,yi)Ϊģʽ������ڵ�ͼ����ϵ�е�λ��  
    do i=1,m
        do j=1,n
            xi=xi0+(i-1)
            yj=yj0-(j-1)
            rl=sqrt(xi**2+yj**2)*d

            !   ��Ŵ�ϵ��rm�Ϳ��ϲ���f
            w2=(rl/rlq)**w1
            sinl=(1.0-w2)/(1.0+w2)
            rm(i,j)=rk*rl/(a*sqrt(1.0-sinl**2))
            f(i,j)=1.4584e-4*sinl
        end do
    end do
    return
    end    
    
!   transmiting boundary valaus  ���̶��߽�ֵ
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

    
!************************��Ҫ���б�д************************��
!   time integrations
    subroutine ti(ua,va,za,ub,vb,zb,uc,vc,zc,rm,f,d,dt,zo,m,n)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
!************************************************************��

!   space smoothing for boundary points �߽�ŵ�ƽ��
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
    
!   transmiting arrays  ���鴫��
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

!   printing variables  ��ӡ���ֲ���
    subroutine pv(na,nb)
    write(*,100) na,nb
100 format(5x,3hna=,i3,5x,3hnb=,i2/)
    return
    end 
    

!************************��Ҫ���б�д************************��
!   space smoothing for internal points ������5��ƽ��(����ƽ��)
!   ��ѡ������ƽ������ƽ��   l=1Ϊִֻ����ƽ����l=2Ϊִ������ƽ��.
    subroutine ssip(a,w,s,m,n,l)
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
!************************************************************
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
    