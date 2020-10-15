"""
    generatesignal!(signal::ReplicaSignal,
                    isreplica::Val{false}=Val(signal.isreplica);
                    t_length=signal.t_length)

Generates local GNSS signal using paramters defined in a
`ReplicaSignal` struct.

Generates a signal with carrier, ADC quantization, noise,
and Neuman sequence.

No need to specify `isreplica`. Set `isreplica` to `true` to
use alternate method, which ignores all `Bool` flags in `signal`.

Specify `t_length` to be ≲ to `replica.t_length` for different
signal generation lengths. **NOTE:** The size of the `replica.data`
array will still be the same size. You will need to keep track
of the `t_length` you passed to `generatesignal!`.
"""
function generatesignal!(signal::ReplicaSignal,
                         # isreplica::Val{false}=Val(signal.isreplica::Bool);
                         t_length=signal.t_length;
                         doppler_curve=missing, doppler_t=signal.t,
                         message="Generating signal...")
    # Common parmeters used for entire signal
    prn = signal.prn
    Tsys = signal.Tsys
    CN0 = signal.CN0
    f_s = signal.f_s
    f_if = signal.f_if
    f_d = signal.f_d
    fd_rate = signal.fd_rate
    ϕ_init = signal.ϕ
    if ismissing(doppler_curve)
        f_d = signal.f_d
        fd_rate = signal.fd_rate
        ϕ_init = signal.ϕ
        get_ϕ(t) = 2π*(f_if + f_d + 0.5*fd_rate*t)*t + ϕ_init
        get_code_val(t) = calc_code_val(signal, t)
    else
        get_code_val, get_ϕ = get_chips_and_ϕ(signal, doppler_curve;
                                              doppler_t=doppler_t)
    end
    B = signal.B
    nADC = signal.nADC
    include_carrier = signal.include_carrier
    include_noise = signal.include_noise
    include_adc = signal.include_adc
    sigtype = eltype(signal.data)
    adc_scale = 2^(nADC-1)-1
    carrier_amp = sqrt(2*k*Tsys)*10^(CN0/20)
    noise_amp = sqrt(k*B*Tsys)
    p = Progress(signal.sample_num, 1, message)
    @threads for i in 1:Int64(float(t_length*f_s))
        @inbounds t = signal.t[i]
        # Generate code value for given signal type
        code_val = get_code_val(t)
        if include_carrier & include_noise
            # Calculate code value with carrier and noise
            ϕ = get_ϕ(t)
            @inbounds signal.data[i] = code_val * carrier_amp * cis(ϕ) +
                                       noise_amp * randn(sigtype)
        elseif include_carrier & ~include_noise
            # Calculate code value with carrier and no noise
            ϕ = get_ϕ(t)
            @inbounds signal.data[i] = code_val * carrier_amp * cis(ϕ) +
                                       noise_amp * randn(sigtype)
        elseif ~include_carrier & include_noise
            # Calculate code value with noise and no carrier
            @inbounds signal.data[i] = code_val + noise_amp * randn(sigtype)
        else
            # Calculate code value only
            @inbounds signal.data[i] = complex(float(code_val))
        end
        next!(p)
    end
    # Quantize signal
    if include_adc
        sigmax = sqrt(maximum(abs2.(signal.data)))
        @threads for i in 1:signal.sample_num
            @inbounds signal.data[i] = round(signal.data[i]*adc_scale/sigmax)
        end
    end
    return signal
end


"""
    generatesignal!(signal::ReplicaSignal,
                    isreplica::Val{true}=Val(signal.isreplica))

Generates local GNSS signal using paramters defined in a
`ReplicaSignal` struct.

Generates a signal with carrier, ADC quantization, noise,
and Neuman sequence.

This version is used only when `isreplica` is set to `true`
in `signal` and ignores all the `include_*` flags in `signal`.
Exponential without the amplitude is included automatically.
"""
function generatesignal!(signal::ReplicaSignal,
                         # isreplica::Val{true}=Val(signal.isreplica::Bool))
                         isreplica::Bool)
    # Common parmeters used for entire signal
    prn = signal.prn
    f_d = signal.f_d
    f_if = signal.f_if
    fd_rate = signal.fd_rate
    ϕ = signal.ϕ
    noexp = signal.noexp
    @threads for i in 1:signal.sample_num
        @inbounds t = signal.t[i]
        # Generate code value for given signal type
        code_val = calc_code_val(signal, t)
        if noexp
            @inbounds signal.data[i] = complex(float(code_val))
        else
            @inbounds signal.data[i] = (code_val *
                                        exp((2π*(f_if + f_d + 0.5*fd_rate*t)*t + ϕ)*1im))
        end
    end
    return signal
end
