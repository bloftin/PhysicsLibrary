module AntennaCarrierLab
using Printf
export cases, parameters, sample, radiation, reference
const C0=BigFloat(299792458)
const EPS=big"8.8541878188e-12"
const ETA=inv(EPS*C0)
const CAP=big"1e-11"
const E=big"1.602176634e-19"
const N=big"8.5e28"
const AREA=big"1e-6"
function cases()
    result=[]
    for id in ["aligned","crossed","oblique","axial","detuned","untuned","lossless","transmit","zero"]
        p=(mode="receive",fMHz=BigFloat(10),f0MHz=BigFloat(10),length=BigFloat(1),E0=BigFloat(1),voltage=BigFloat(1),theta=BigFloat(90),psi=BigFloat(0),loss=big".5",load=BigFloat(1),source=BigFloat(50),tuning=true)
        id=="crossed"&&(p=merge(p,(psi=BigFloat(90),)))
        id=="oblique"&&(p=merge(p,(theta=BigFloat(45),psi=BigFloat(30))))
        id=="axial"&&(p=merge(p,(theta=BigFloat(0),)))
        id=="detuned"&&(p=merge(p,(fMHz=big"10.05",)))
        id=="untuned"&&(p=merge(p,(tuning=false,)))
        if id=="lossless"
            p=merge(p,(loss=BigFloat(0),));p=merge(p,(load=parameters(p).rad,))
        end
        id=="transmit"&&(p=merge(p,(mode="transmit",)))
        id=="zero"&&(p=merge(p,(E0=BigFloat(0),voltage=BigFloat(0))))
        push!(result,id=>p)
    end
    result
end
function parameters(p)
    f=p.fMHz*big"1e6";omega=2big(pi)*f;lambda=C0/f;heff=p.length/2;k=2big(pi)/lambda
    rad=ETA*k^2*heff^2/(6big(pi));ra=rad+p.loss
    inductance=p.tuning ? inv((2big(pi)*p.f0MHz*big"1e6")^2*CAP) : BigFloat(0)
    reactance=omega*inductance-inv(omega*CAP)
    projection=sinpi(p.theta/180)*cospi(p.psi/180)
    drive=p.mode=="receive" ? p.E0*heff*projection : p.voltage
    termination=p.mode=="receive" ? p.load : p.source
    current=drive/Complex(ra+termination,reactance)
    peak=abs(current);i2=peak^2/2
    (;f,omega,lambda,heff,k,rad,ra,inductance,reactance,current,peak,qPeak=peak/omega,drive,termination,
        supplied=real(drive*conj(current))/2,heat=i2*p.loss,radiated=i2*rad,terminationPower=i2*termination,
        excursion=peak/(omega*N*E*AREA),aperture=ETA*heff^2*projection^2/(4ra))
end
function sample(p,cycles)
    m=parameters(p);phasor=cispi(2cycles)
    current=real(m.current*phasor);charge=real(m.current/(im*m.omega)*phasor)
    (;current,charge,drive=m.drive*real(phasor),terminal=current*m.termination,
        displacement=-charge/(N*E*AREA),velocity=-current/(N*E*AREA),
        uC=charge^2/(2CAP),uL=m.inductance*current^2/2)
end
function radiation(p,cycles,rLambda=big"3.25",theta=BigFloat(60))
    m=parameters(p);r=rLambda*m.lambda
    phasor=im*ETA*m.k*m.heff*m.current*sinpi(theta/180)/(4big(pi)*r)*cispi(2*(cycles-rLambda))
    eTheta=real(phasor)
    (;eTheta,bPhi=eTheta/C0,flux=eTheta^2/ETA,average=abs(phasor)^2/(2ETA))
end
fmt(x)=x isa AbstractString ? x : @sprintf("%.17g",Float64(x))
function reference(folder=@__DIR__)
    open(joinpath(folder,"parameters.csv"),"w") do io
        println(io,"case,lambda_m,heff_m,Rrad_ohm,reactance_ohm,I_peak_A,q_peak_C,P_input_W,P_term_W,P_heat_W,P_rad_W,excursion_m,aperture_m2")
        for (id,p) in cases()
            m=parameters(p);println(io,join(fmt.([id,m.lambda,m.heff,m.rad,m.reactance,m.peak,m.qPeak,m.supplied,m.terminationPower,m.heat,m.radiated,m.excursion,m.aperture]),","))
        end
    end
    open(joinpath(folder,"reference.csv"),"w") do io
        println(io,"case,cycles,drive_V,current_A,q_upper_C,terminal_V,electron_displacement_m,electron_velocity_m_s,U_C_J,U_L_J,Etheta_V_m,Bphi_T,S_W_m2,S_average_W_m2")
        for (id,p) in cases(),i in 0:128
            cycles=BigFloat(i)/64;s=sample(p,cycles);r=radiation(p,cycles)
            println(io,join(fmt.([id,cycles,s.drive,s.current,s.charge,s.terminal,s.displacement,s.velocity,s.uC,s.uL,r.eTheta,r.bPhi,r.flux,r.average]),","))
        end
    end
end
end
if abspath(PROGRAM_FILE)==@__FILE__
    AntennaCarrierLab.reference()
end
