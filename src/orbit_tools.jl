"""
    Satellite
"""
struct Satellite
    id
    init_orbit
    t
    orbit
    r_ecef
    v_ecef
    a_ecef
end


"""
    Constellation
"""
struct Constellation
    epoch
    plane_num
    satellite_per_plane
    Ω₀
    f₀
    ω
    e
    i
    t_range
    ΔΩ
    Δf
    satellites
end


"""
    get_eop()
"""
function get_eop()
    return get_iers_eop(:IAU1980)
end


"""
    define_constellation(plane_num, sat_per_plane, inclination)

Set `ΔΩ` to 30ᵒ if simulating sun-sync constellation, such as Iridium, otherwise,
`ΔΩ` will default to `360/plane_num`.
"""
function define_constellation(a, plane_num, satellite_per_plane, incl, t_range;
                              eop=get_eop(), show_plot=true,
                              Ω₀=0., f₀=0., ω=0., e=0., t_start=0., obs_lla=missing,
                              ΔΩ=360/plane_num, a_lim=1, ax=missing, figsize=missing,
                              print_steps=true)
    a = float(a)
    incl = incl*π/180
    t_range = float.(t_range) ./ (60*60*24) .+ t_start
    ΔΩ = ΔΩ*π/180
    Δf = 2π/satellite_per_plane
    if f₀ == 0.
        f₀ += Δf/satellite_per_plane
    end
    k = 1
    if print_steps
        p = Progress(Int(plane_num*satellite_per_plane), 1,
                     "Generating constellation...")
    end
    if show_plot && ismissing(ax)
        if ismissing(figsize)
            fig = figure()
        else
            fig = figure(figsize=figsize)
        end
        fig, ax = make_subplot(fig, 1, 1, 1; projection3d=true)
    end
    satellites = Array{Satellite}(undef, plane_num*satellite_per_plane)
    for plane in 1:plane_num
        for sat in 1:satellite_per_plane
            id = k
            Ω = Ω₀ + (plane-1)*ΔΩ
            f = f₀ + (sat-1)*Δf
            init_orbit = init_orbit_propagator(Val(:twobody), 0., a, e, incl,
                                               Ω, ω, f)
            orbit, r, v = propagate_to_epoch!(init_orbit, t_range)
            r_ecef = Array{Float64,2}(undef, length(orbit), 3)
            v_ecef = Array{Float64,2}(undef, length(orbit), 3)
            a_ecef = Array{Float64,2}(undef, length(orbit), 3)
            for i in 1:length(orbit)
                orbit_teme = kepler_to_sv(orbit[i])
                orbit_ecef = svECItoECEF(orbit_teme, TEME(), ITRF(), t_start, eop)
                r_ecef[i,:] = [orbit_ecef.r[1], orbit_ecef.r[2], orbit_ecef.r[3]]
                v_ecef[i,:] = [orbit_ecef.v[1], orbit_ecef.v[2], orbit_ecef.v[3]]
                a_ecef[i,:] = [orbit_ecef.a[1], orbit_ecef.a[2], orbit_ecef.a[3]]
            end
            satellites[k] = Satellite(id, init_orbit, t_range, orbit, r_ecef,
                                      v_ecef, a_ecef)
            k += 1
            if show_plot
                scatter3D(r_ecef[1,1], r_ecef[1,2], r_ecef[1,3], s=50)
                plot3D(satellites[k-1].r_ecef[:,1], satellites[k-1].r_ecef[:,2],
                       satellites[k-1].r_ecef[:,3], "k")
            end
            if print_steps
                next!(p)
            end
        end
    end
    if show_plot
        axis("off")
        if ~ismissing(obs_lla)
            obs_ecef = GeodetictoECEF(obs_lla[1], obs_lla[2], obs_lla[3])
            scatter3D(obs_ecef[1], obs_ecef[2], obs_ecef[3], s=300, c="r",
                      marker="*", facecolor="white")
        end
        u = Array(range(0, 2π, length=100))
        v = Array(range(0, 1π, length=100))
        u, v = meshgrid(u, v)
        x = Rₑ.*cos.(u).*sin.(v)
        y = Rₑ.*sin.(u).*sin.(v)
        z = Rₑ.*cos.(v)
        plot_wireframe(x, y, z, color="grey", linestyle=":", rcount=20, ccount=30)
        ax.axes.set_xlim3d(left=-a*a_lim/2, right=a*a_lim/2)
        ax.axes.set_ylim3d(bottom=-a*a_lim/2, top=a*a_lim/2)
        ax.axes.set_zlim3d(bottom=-a*a_lim/2, top=a*a_lim/2)
    end
    return Constellation(t_start, plane_num, satellite_per_plane, Ω₀, f₀, ω, e, incl,
                         t_range, ΔΩ, Δf, satellites)
end


"""
doppler_distribution(a, plane_num, satellite_per_plane, incl, t_range,
                     obs_lla, sig_freq; eop=get_iers_eop(:IAU1980),
                     Ω₀=0., f₀=0., show_plot=true, ω=0., e=0.,
                     t_start=0., ΔΩ=360/plane_num, min_elevation=5.,
                     show_hist=true, bins=100)
"""
function doppler_distribution(a, plane_num, satellite_per_plane, incl, t_range,
                              obs_lla, sig_freq; eop=get_eop(),
                              Ω₀=0., f₀=0., show_plot=true, ω=0., e=0.,
                              t_start=0., ΔΩ=360/plane_num, min_elevation=5.,
                              bins=100, heatmap_bins=[bins, bins], a_lim=1.25,
                              figsize=missing, print_steps=true)
    if show_plot
        if ismissing(figsize)
            fig = figure()
        else
            fig = figure(figsize=figsize)
        end
        fig, ax1 = make_subplot(fig, 2, 2, 1; projection3d=true)
    else
        ax1 = missing
    end
    constellation = define_constellation(a, plane_num, satellite_per_plane, incl,
                                         t_range; eop=eop, show_plot=show_plot,
                                         Ω₀=Ω₀, f₀=f₀, ω=ω, e=e, t_start=t_start,
                                         obs_lla=obs_lla, ΔΩ=ΔΩ, ax=ax1, a_lim=a_lim,
                                         print_steps=print_steps)
    obs_ecef = GeodetictoECEF(obs_lla[1], obs_lla[2], obs_lla[3])
    N = length(t_range)*plane_num*satellite_per_plane
    ts = Array{Float64}(undef, N)
    ids = Array{Int}(undef, N)
    dopplers = Array{Float64}(undef, N)
    elevations = Array{Float64}(undef, N)
    k = 1
    j = 1
    for satellite in constellation.satellites
        for i in 1:length(satellite.t)
            r = view(satellite.r_ecef, i, :)
            sat_range, azimuth, elevation = calcelevation(r, obs_lla)
            if elevation >= min_elevation
                v = view(satellite.v_ecef, i, :)
                dopplers[k] = calcdoppler(r, v, obs_ecef, sig_freq)
                elevations[k] = elevation
                ts[k] = satellite.t[i]
                ids[k] = satellite.id
                k += 1
            end
        end
    end
    dopplers = dopplers[1:k-1]
    elevations = elevations[1:k-1]
    doppler_means = Array{Float64}(undef, N)
    doppler_rates = Array{Float64}(undef, N)
    doppler_rate_ts = Array{Float64}(undef, N)
    ts = ts[1:k-1]
    ts_diff = diff(ts).*(60*60*24)
    Δt = t_range[2] - t_range[1]
    ids = ids[1:k-1]
    ids_diff = diff(ids)
    k = 1
    for i in 1:length(ts_diff)
        if (ts_diff[i] < (Δt + 0.001)) && (ids_diff[i] == 0)
            doppler_means[k] = (dopplers[i+1] + dopplers[i])/2
            doppler_rates[k] = (dopplers[i+1] - dopplers[i])/Δt
            doppler_rate_ts[k] = (ts[i+1] + ts[i])/2
            k += 1
        end
    end
    doppler_means = doppler_means[1:k-1]
    doppler_rates = doppler_rates[1:k-1]
    doppler_rate_ts = doppler_rate_ts[1:k-1]
    if show_plot
        fig, ax2 = make_subplot(fig, 2, 2, 2; aspect="auto")
        hist2D(doppler_means./1000, doppler_rates, bins=heatmap_bins)
        xlabel("Doppler (kHz)")
        ylabel("Doppler Rate (Hz/s)")
        colorbar()
        fig, ax3 = make_subplot(fig, 2, 2, 3; aspect="auto")
        hist(doppler_means./1000, bins=bins, density=true)
        xlabel("Doppler (kHz)")
        ylabel("Prob")
        fig, ax4 = make_subplot(fig, 2, 2, 4; aspect="auto")
        hist(doppler_rates, bins=bins, density=true)
        xlabel("Doppler (Hz/sec)")
        ylabel("Prob")
        suptitle("Incination: $(round(incl, digits=0))ᵒ; a: $(Int(round(a/1000, digits=0)))km; Plane #: $(plane_num); Sat #: $(plane_num*satellite_per_plane)\nUser loc: ($(round(obs_lla[1], digits=3))ᵒ, $(round(obs_lla[2], digits=3))ᵒ, $(round(obs_lla[3], digits=3))m)\nSignal Freq: $(sig_freq)Hz")
    end
    return (doppler_means, doppler_rates, doppler_rate_ts, ids, elevations)
 end



"""
    plot_satellite_orbit(satellite::Satellite; user_lla=missing)
"""
function plot_satellite_orbit(satellite::Satellite; obs_lla=missing)
    figure()
    ax = subplot()
    # Plot Earth
    u = Array(range(0, 2π, length=100))
    v = Array(range(0, 1π, length=100))
    u, v = meshgrid(u, v)
    x = Rₑ.*cos.(u).*sin.(v)
    y = Rₑ.*sin.(u).*sin.(v)
    z = Rₑ.*cos.(v)
    plot_wireframe(x, y, z, color="grey", linestyle=":", rcount=20, ccount=30)
    # Plot user location
    if ~ismissing(obs_lla)
        obs_ecef = GeodetictoECEF(obs_lla[1], obs_lla[2], obs_lla[3])
        scatter3D(obs_ecef[1], obs_ecef[2], obs_ecef[3], s=300, c="r",
                  marker="*", facecolor="white")
    end
    # Plot satellite
    scatter3D(satellite.r_ecef[1,1], satellite.r_ecef[1,2],
              satellite.r_ecef[1,3], s=50)
    plot3D(satellite.r_ecef[:,1], satellite.r_ecef[:,2],
           satellite.r_ecef[:,3], "k")
    axis("off")
end