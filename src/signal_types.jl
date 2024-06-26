"""
    CodeType


Struct for holding parms for a custum code type for either the `I` or `Q`
channel


Fields:

- `name::String`: name of code type
- `code_num::Int`: number of codes, including databits, on channel
- `codes::Array{Dict,1}`: array of dictionaries, where each dictionary is a
                          layer of code
- `chipping_rates::Array{Float,1}`: array of chipping rates in Hz for each code
- `include_codes::Array{Bool,1}`: array of `Bool` flags for each code to indicate
                                  whether a given code is being used
- `databits::Bool`: `Bool` flag to specify whether databits used in the set of codes
    * if `true`, databits are the last code in `CodeType.codes` array
- `similar_databits::Bool`: set to true if the databits are the same for all PRNs
"""
struct CodeType{T1,T2,T3,T4,T5}
    name::String           # Name of code type
    code_num::T1           # Number of codes in signal type
                           # Includes primary, secondary, and nav codes
    codes::T2              # Vector of dictionaries
                           # Each dictionary is a primary, secondary, or
                           # or nav code which is specific for each PRN number
                           # The last dictionary in the vector of `codes` is
                           # assumed to be the navbits. This "code" will be
                           # ignored when generating replica signals for
                           # acquisition, fine acquisition, and signal tracking
                           # methods. Primary codes are considered the
                           # first code in `codes`.
    chipping_rates::T3     # Vector of chipping rates of length `code_num`
    code_lengths::T4       # Vector of code lengths of length `code_num`
    include_codes::T5      # Bool vector of length `code_num`
                           # Used to determine if a given code is used for
                           # signal generation.
                           # Will be used in `calc_code_val` method to determine
                           # if a code value will be calculated and XOR`ed to
                           # other code values.
    databits::Bool         # Flag for if there are databits present in code
                           # Databits are assumed to be last entry in the
                           # vector of codes given to definecodetype funciton.
    similar_databits::Bool # True if databits are similar for all PRNs
end


"""
    SignalType


Holds common parms for a signal including its codes for each channel.


Fields:

- `name:String`: name of the signal type
- `I_codes::CodeType`: Custum codes for the I channel of the signal
    * set to `missing` if no `I_codes` given
- `Q_codes::CodeType`: Custum codes for the Q channel of the signal
    * set to `missing` if no `I_codes` given
- `sig_freq::Float64`: carrier frequency of the signal in Hz
- `B_I::Float64`: maximum bandwidth of all I channel codes in Hz
- `B_Q::Float64`: maximum bandwidth of all Q channel codes in Hz
- `include_I::Bool`: set to `true` if `I_codes` is given
- `include_Q::Bool`: set to `true` if `Q_codes` is given
"""
struct SignalType{T1,T2,T3,T4,T5,T6}
    name::T1
    I_codes::T2
    Q_codes::T3
    sig_freq::T4
    B_I::T5
    B_Q::T6
    include_I::Bool
    include_Q::Bool
end


"""
    definecodetype(codes::Vector, chipping_rates::Vector{Float64};
                   databits=missing, name="custom")


Defines a `CodeType` struct that represents the codes of a signal on a
given channel, `I`, `Q`, or `both`.


Required Arguments:

- `codes::Vector`: array of codes, `not including databits`
    * the code is considered the primary code `(NOTE: this must be a dictionary)`
    * dictionary keys are the PRN numbers
    * all other codes after can be either dictionaries or arrays
    * if the code is an array, it is assumed that that layer of code is the
      same for all PRNs
- `chipping_rates::Vector{Float}`: array of chipping rates for codes above,
                                   `not including databits`


Optional Arguments:

- `databits::Vector`: if specified by user, must be a two element
                      array where the first element is the databits
                      as either a dictionary or array and the second
                      element is the chipping rate in Hz of the
                      databits `(default = missing)`
- `name::String`: name of code type `(default is "custom")`


Returns:

- `CodeType` structure
"""
function definecodetype(codes::Vector, chipping_rates::Vector{Float64};
                        databits=missing, name="custom")
    # Check that the first code in `codes`, the primary code, is a Dict
    if ~isa(codes[1], Dict)
        error("Primary code must be a dictionary of codes. The primary code is the first index of `codes`.")
    end
    # Setup for if there is or isn't databits
    if ismissing(databits)
        code_num = length(codes)
        N = code_num
    else
        code_num = length(codes) + 1
        N = code_num - 1
    end
    # Obtain the dictionary keys from the primary code and create Vector of
    # codes of the same dictionary type
    code_keys = collect(keys(codes[1]))
    dict_type = Dict{eltype(code_keys),Vector{eltype(codes[1][code_keys[1]])}}
    signal_codes = Vector{dict_type}(undef, code_num)
    code_lengths = Array{Int}(undef, code_num)
    # Loop through codes and convert non-dict items to dictionaries
    for i in 1:N
        # Check if item in vector is a dictionary.
        # If it is, it is placed into `signal_codes[i]`, otherwise, it is
        # assumed that the item in the `codes` vector is a single code
        # that is applied to all PRNs. It is then copied into a dictionary
        # and associated with all dictionary keys, the PRN numbers.
        if isa(codes[i], Dict)
            signal_codes[i] = codes[i]
            code_lengths[i] = length(codes[i][collect(keys(codes[i]))[1]])
        else
            code = dict_type()
            code_lengths[i] = length(codes[i])
            for code_key in code_keys
                code[code_key] = codes[i]
            end
            signal_codes[i] = code
        end
    end
    # Repeat the above process for databits, if they are given. The same
    # treatment above is used for the databits.
    if ~ismissing(databits)
        push!(chipping_rates, databits[2])
        included_databits = true
        databit_codes = databits[1]
        if isa(databit_codes, Dict)
            similar_databits = false
            signal_codes[code_num] = databit_codes
            code_lengths[code_num] = length(databit_codes[collect(keys(databit_codes))[1]])
        else
            similar_databits = true
            code = dict_type()
            code_lengths[code_num] = length(databit_codes)
            for code_key in code_keys
                code[code_key] = databit_codes
            end
            signal_codes[code_num] = code
        end
    else
        included_databits = false
        similar_databits = false
    end
    include_codes = fill(true, code_num)
    return CodeType(name, code_num, signal_codes, chipping_rates, code_lengths,
                    include_codes, included_databits, similar_databits)
end


"""
    definecodetype(code::Dict, chipping_rate::Float64;
                   databits=missing, name="custom")


Defines a `CodeType` struct that represents the codes of a signal on a
given channel, `I`, `Q`, or `both`.


Required Arguments:

- `code::Dict`: dictionary of primary codes where the keys are the PRN numbers
- `chipping_rate::Float`: chipping rate in Hz for the primary code above


Optional Arguments:

- `databits::Vector`: if specified by user, must be a two element
                      array where the first element is the databits
                      as either a dictionary or array and the second
                      element is the chipping rate in Hz of the
                      databits `(default = missing)`
- `name::String`: name of code type `(default is "custom")`


Returns:

- `CodeType` structure
"""
function definecodetype(code::Dict, chipping_rate::Float64;
                        databits=missing, name="custom")
    # Check that the first code in `codes`, the primary code, is a Dict
    if ~isa(code, Dict)
        error("Code given must be in the form of a dictionary.")
    end
    # Obtain the dictionary keys from the primary code and create Vector of
    # codes of the same dictionary type
    include_code = true
    code_keys = collect(keys(code))
    dict_type = Dict{eltype(code_keys),Vector{eltype(code[code_keys[1]])}}
    code_length = length(code[code_keys[1]])
    # Check if databit codes given is a dictionary or array.
    # If it is, it is placed into `signal_codes[2]`, otherwise, it is
    # assumed that is a single that is applied to all PRNs. It is then copied
    # into a dictionary and associated with all dictionary keys, the PRN numbers.
    if ~ismissing(databits)
        code_num = 2
        signal_codes = Vector{dict_type}(undef, code_num)
        signal_codes[1] = code
        chipping_rate = [chipping_rate, databits[2]]
        included_databits = true
        databit_codes = databits[1]
        if isa(databit_codes, Dict)
            similar_databits = false
            signal_codes[code_num] = databit_codes
            code_length = [code_length, length(databit_codes[code_keys[1]])]
        else
            similar_databits = true
            code = dict_type()
            code_length = [code_length, length(databit_codes)]
            for code_key in code_keys
                code[code_key] = databit_codes
            end
            signal_codes[code_num] = code
        end
    else
        code_num = 1
        included_databits = false
        signal_codes = [code]
        similar_databits = false
    end
    include_codes = fill(true, code_num)
    return CodeType(name, code_num, signal_codes, chipping_rate, code_length,
                    include_codes, included_databits, similar_databits)
end


"""
    definesignaltype(I_codes::CodeType, Q_codes::CodeType, sig_freq;
                     name="custom")


Defines a signal type with `CodeType` structs defined for both the `I` and `Q`
channels.


Required Arguments:

- `I_codes::CodeType`: Custum codes for the I channel of the signal
- `Q_codes::CodeType`: Custum codes for the Q channel of the signal
- `sig_freq::Float64`: carrier frequency of signal in Hz


Optional Arguments:

- `name::String`: name of signal type `(default is "custom")`
- `B`: receiver bandwidth `(default is based off max B in I_codes and Q_codes)`


Returns:

- `SignalType` struct
"""
function definesignaltype(I_codes::CodeType, Q_codes::CodeType, sig_freq;
                          name="custom", B=missing)
    if ismissing(B)
        # Determine maximum bandwidth for I channel codes
        B_I = 2*maximum(I_codes.chipping_rates)
        # Determine maximum bandwidth for Q channel codes
        B_Q = 2*maximum(Q_codes.chipping_rates)
    else
        B_I = B
        B_Q = B
    end
    return SignalType(name, I_codes, Q_codes, sig_freq, B_I, B_Q, true, true)
end


"""
    definesignaltype(codes::CodeType, sig_freq, channel="I"; name="custom")


Defines a signal type with a `CodeType` struct defined for either the `I`, `Q`,
or `both` channels.


Required Arguments:

- `codes::CodeType`: Custum codes for either the `I`, `Q`, or `both` channels
- `sig_freq::Float64`: carrier frequency of signal in Hz


Optional Arguments:

- `channel::String`: set to either `I`, `Q`, or `both` (default is `I`)
- `name::String`: name of signal type (default is `custom`)
- `B`: receiver bandwidth `(default = 2*maximum(codes.chipping_rates))`


Returns:

- `SignalType` struct
"""
function definesignaltype(codes::CodeType, sig_freq, channel="I"; name="custom",
                          B=missing)
    # Determine maximum bandwidth for codes
    if ismissing(B)
        B = 2*maximum(codes.chipping_rates)
    end
    if channel == "both"
        return SignalType(name, codes, codes, sig_freq, B, B, true, true)
    elseif channel == "I"
        return SignalType(name, codes, missing, sig_freq, B, missing, true, false)
    elseif channel == "Q"
        return SignalType(name, missing, codes, sig_freq, missing, B, false, true)
    else
        error("Invalid channel specified.")
    end
end


"""
    GNSSSignal


The most general type of signal type used in `GNSSTools`. Used for both
`GNSSData` and `ReplicaSignal` structs.
"""
abstract type GNSSSignal end


"""
    Data


Structure for holding GNSS signal data.


Fields:

- `file_name::String`: name of data file
- `f_s::Float64`: sampling rate of data in Hz
- `f_if::Float64`: IF frequency of data in Hz
- `t_length::Float64`: length of data loaded in seconds
- `start_data_idx::Int`: starting index in the data file
- `data::Array{Complex{Float64},1}`: loaded data from data file
- `data_type::String`: a `Symbol` type either `:sc4` or `:sc8` for 4 and 8 bit
                       comeplex data, respectively
- `data_start_time::T1`: `Tuple` of length 6
    * format is `(year, month, day, hour, minute, second)`
    * everything other than `second` must be an integer
    * `second` can be an integer or float
    * set to `missing` if no start time given
- `site_loc_lla::T2`: data collection site location
    * format is `(latitude, longitude, height)`
    * `latitude` and `longitude` are in degrees
    * `height` is in meters
    * set to `missing` if no site location given
- `sample_num::Int`: number of data samples in `Data.data`
- `total_data_length::Float64`: total length of data file in seconds
- `nADC::Int`: bit depth of data
    * `sc4` is 4 bit
    * `sc8` is 8 bit
- `start_t::Float64`: the start time of the signal in seconds
"""
struct GNSSData{T1,T2,T3} <: GNSSSignal
    file_name::String
    f_s::Float64
    f_if::Float64
    t_length::Float64
    start_data_idx::Int
    data::Array{T3,1}
    data_type::String
    data_start_time::T1
    site_loc_lla::T2
    sample_num::Int
    total_data_length::Float64
    nADC::Int
    start_t::Float64
end


"""
    GNSSData(file_name, f_s, f_if, t_length, start_data_idx, t, 
             data::Array{T3,1}, data_type, data_start_time::T1, 
             site_loc_lla::T2, sample_num, total_data_length, 
             nADC, start_t) where {T1, T2, T3}


Outer constructor function for `GNSSData` struct initialization.


Returns:

- `GNSSData` struct
"""
function GNSSData(file_name, f_s, f_if, t_length, start_data_idx,  
                  data::Array{T3,1}, data_type, data_start_time::T1, 
                  site_loc_lla::T2, sample_num, total_data_length, 
                  nADC, start_t) where {T1, T2, T3}
    return GNSSData{T1,T2,T3}(file_name, f_s, f_if, t_length, start_data_idx,
                              data, data_type, data_start_time, site_loc_lla, 
                              sample_num, total_data_length, nADC, start_t)
end


"""
    ReplicaSignal


A abstract struct for the replica signal structs.


Fields:

- `name::String`: name of replica signal
- `prn::Int`: code PRN to be generated
- `f_s::Float64`: receiver sampling rate of signal in Hz
- `t_length::Float64`: data length in seconds
- `f_if::Float64`: IF frequency in Hz
- `f_d::Float64`: initial carrier Doppler frequency in Hz
- `fd_rate::Float64`: initial carrier Doppler frequency rate in Hz
- `Tsys::Float64`: receiver noise temperature in Kelvin
- `CN0::Float64`: signal carrier to noise ratio (C/N₀)
- `phi::Float64`: initial carrier phase in radians
- `nADC::Int64`: bit depth of receiver
- `code_start_idx::Float64`: index in `ReplicaSignal.data` where all codes in
                             signal start
- `init_code_phases_I::T1`: array of initial code phases for all I channel codes
    * vector length is set to 0 if there are no I channel codes
- `init_code_phases_Q::T2`: array of initial code phases for all Q channel codes
    * vector length is set to 0 if there are no Q channel codes
- `data::Array{Complex{Float64},1}`: where the signal raw I/Q samples are stored
- `include_carrier::Bool`: flag for if signal will be modulated onto a carrier
- `include_adc::Bool`: flag for if signal will undergo ADC quantization
- `include_thermal_noise::Bool`: flag for if thermal noise will be added
- `include_databits_I::Bool`: flag for if databits on the I channel will be put
                              onto signal
- `include_databits_Q::Bool`: flag for if databits on the Q channel will be put
                              onto signal
- `include_phase_noise::Bool`: flag for if phase noise will be added onto signal
- `f_code_d_I::T2`: adjusted chipping rate due to Doppler frequency for I
                    channel codes
    * vector length is set to 0 if there are no I channel codes
- `f_code_dd_I::T3`: adjusted chipping rate rate due to Doppler frequency rate
                     for I channel codes
    * vector length is set to 0 if there are no I channel codes
- `f_code_d_Q::T4`: adjusted chipping rate due to Doppler frequency for Q
                    channel codes
    * vector length is set to 0 if there are no Q channel codes
- `f_code_dd_Q::T5`: adjusted chipping rate rate due to Doppler frequency rate
                     for Q channel codes
    * vector length is set to 0 if there are no Q channel codes
- `sample_num::Int`: number of raw I/Q samples in `ReplicaSignal.data`
- `isreplica::Bool`: flag used to specify that a given `ReplicaSignal` struct
                     will be used as a replica for signal processing
    * if `true`, a `ReplicaSignal` struct will not have noise added onto it
      and will not undergo ADC quantization
    * signal generation will be done using the second method of `generatesignal!`,
      `generatesignal!(signal::ReplicaSignal, isreplica::Bool)`
- `noexp::Bool`: used only if second method of `generatesignal!`, discussed
                 above, is used
    * does not modulate codes onto carrier
- `thermal_noise::Array{Complex{Float64},1}`: contains pre-build thermal noise
                                              vector
    * if `allocate_noise_vectors` is set to `for variable

    endalse` in `definesignal` method,
      the size of this vector is 0, indicating that it will not be used
- `phase_noise::Array{Float64,1}`: contains pre-build phase noise vector
    * if `allocate_noise_vectors` is set to `false` in `definesignal` method,
      the size of this vector is 0, indicating that it will not be used
- `signal_type::T7`: a `SignalType` struct that was used to define the signal
- `receiver_h_parms::Array{Float64,1}`:
- `start_t::Float64`: the start time of the signal in seconds

"""
mutable struct ReplicaSignal{T} <: GNSSSignal
    name::String
    prn::Int
    f_s::Float64
    t_length::Float64
    f_if::Float64
    f_d::Float64
    fd_rate::Float64
    Tsys::Float64
    CN0::Float64
    phi::Float64
    nADC::Int
    code_start_idx::Rational{Int}
    init_code_phases_I::Array{Float64,1}
    init_code_phases_Q::Array{Float64,1}
    data::Array{Complex{Float64},1}
    include_carrier::Bool
    include_adc::Bool
    include_thermal_noise::Bool
    include_databits_I::Bool
    include_databits_Q::Bool
    include_phase_noise::Bool
    f_code_d_I::Array{Float64,1}
    f_code_dd_I::Array{Float64,1}
    f_code_d_Q::Array{Float64,1}
    f_code_dd_Q::Array{Float64,1}
    sample_num::Int
    isreplica::Bool
    noexp::Bool
    thermal_noise::Array{Complex{Float64},1}
    phase_noise::Array{Complex{Float64},1}
    signal_type::T
    receiver_h_parms::Array{Float64,1}
    start_t::Float64
end


"""
    ReplicaSignal(name, prn, f_s, t_length, f_if, f_d, fd_rate, Tsys,
                  CN0, phi, nADC, code_start_idx, init_code_phases_I,
                  init_code_phases_Q, t, data, include_carrier,
                  include_adc, include_thermal_noise, include_databits_I,
                  include_databits_Q, include_phase_noise, f_code_d_I,
                  f_code_dd_I, f_code_d_Q, f_code_dd_Q, sample_num,
                  isreplica, noexp, thermal_noise, phase_noise,
                  signal_type::T, receiver_h_parms, start_t) where {T}


Outer constructor function for `ReplicaSignal` struct initialization.


Returns:

- `ReplicaSignal` struct
"""
function ReplicaSignal(name, prn, f_s, t_length, f_if, f_d, fd_rate, Tsys,
                       CN0, phi, nADC, code_start_idx, init_code_phases_I,
                       init_code_phases_Q, data, include_carrier,
                       include_adc, include_thermal_noise, include_databits_I,
                       include_databits_Q, include_phase_noise, f_code_d_I,
                       f_code_dd_I, f_code_d_Q, f_code_dd_Q, sample_num,
                       isreplica, noexp, thermal_noise, phase_noise,
                       signal_type::T, receiver_h_parms, start_t) where {T}
    return ReplicaSignal{T}(name, prn, f_s, t_length, f_if, f_d, fd_rate, Tsys,
                            CN0, phi, nADC, code_start_idx, init_code_phases_I,
                            init_code_phases_Q, data, include_carrier,
                            include_adc, include_thermal_noise, include_databits_I,
                            include_databits_Q, include_phase_noise, f_code_d_I,
                            f_code_dd_I, f_code_d_Q, f_code_dd_Q, sample_num,
                            isreplica, noexp, thermal_noise, phase_noise,
                            signal_type, receiver_h_parms, start_t)
end


"""
    ReplicaSignals


Struct containing array of `ReplicaSignal` structs to generate a signal that
contains signals from multiple PRNs.


Fields:

- `name::String`:
- `replica_signals::Array{ReplicaSignal,1}`:
- `data::Array{Complex{Float64},1}`:
- `t::Array{Float64,1}`:
- `f_s::Float64`:
- `f_if::Float64`:
- `sample_num::Int`:
- `nADC::Int`:
- `thermal_noise::Array{Complex{Float64},1}`:
- `phase_noise::Array{Float64,1}`:
- `start_t::Float64`: the start time of the signal in seconds
"""
mutable struct ReplicaSignals <: GNSSSignal
    name::String
    replica_signals::Array{ReplicaSignal,1}
    data::Array{Complex{Float64},1}
    t_length::Float64
    f_s::Float64
    f_if::Float64
    B::Float64
    Tsys::Float64
    sample_num::Int
    nADC::Int
    include_carrier::Bool
    include_adc::Bool
    include_thermal_noise::Bool
    include_phase_noise::Bool
    thermal_noise::Array{Complex{Float64},1}
    phase_noise::Array{Complex{Float64},1}
    receiver_h_parms::Array{Float64,1}
    start_t::Float64
end
