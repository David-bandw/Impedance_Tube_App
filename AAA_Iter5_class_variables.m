classdef AAA_Iter5_class_variables < handle 

    properties 

        %loaded data properties
        excitation; 
        fs; 
        M12_data_ch1_Pa; 
        M12_data_ch2_Pa; 
        M21_data_ch1_Pa; 
        M21_data_ch2_Pa; 
        mic1_sensitivity; 
        mic2_sensitivity; 
        t;

        %Calculated variables
        alphaIR_AVG;

        x=1;
        c0;
        f;
        filename;
        H12ir_AVG;
        hiIR;
        hrIR;
        k;
        kIR;
        kw_AVG;
        len;
        M12_alphaIR;
        M12_c;
        M12_delay;
        M12_freq;
        M12_H1ir;
        M12_H2ir;
        M12_H12ir;
        M12_irS1;
        M12_irS2;
        M12_kw;
        M12_lags;
        M12_rIR;
        M12_Z;
        M21_alphaIR;
        M21_c;
        M21_delay;
        M21_freq;
        M21_H1ir;
        M21_H2ir;
        M21_H12ir;
        M21_irS1;
        M21_irS2;
        M21_kw;
        M21_lags;
        M21_rIR;
        M21_Z;
        nfft;
        num_figures_open_1; 
        num_figures_open_2; 
        num_figures_open_3; 
        rIR_AVG;
        rho;
        s1;
        sample_th;
        selected_title; 
        t1;
        z1;
        z2;
        Z_AVG;




    end

    methods 

        function set_global_variables(obj)

            obj.c0 = 343; 
            obj.rho = 1.21; 
            obj.sample_th = 65e-3;
            obj.s1 = 35e-3;
            obj.z1 = 124e-3; 
            obj.z2 = obj.z1 - obj.s1; 

            obj.len = length(obj.t);                       % length of a signal
            obj.nfft = 2^nextpow2(obj.len);                % N-Point FFT
            obj.f = obj.fs/2*linspace(0,1,obj.nfft/2+1);   % frequency vector
            obj.k = 2*pi.*obj.f./obj.c0;                   % wavenumber vector

        end

       
        %%IR based on A-lab 
        function create_IR(obj)

            obj.t1 = obj.t';

            obj.M12_irS1 = impzest(obj.excitation, obj.M12_data_ch1_Pa); 
            obj.M12_irS2 = impzest(obj.excitation, obj.M12_data_ch2_Pa);
            obj.M21_irS1 = impzest(obj.excitation, obj.M21_data_ch1_Pa); 
            obj.M21_irS2 = impzest(obj.excitation, obj.M21_data_ch2_Pa);

            obj.t1 = obj.t(1:length(obj.M12_irS1)); 

            [obj.M12_c, obj.M12_lags] = xcorr(obj.M12_irS2, obj.M12_irS1,40,'coeff');
            obj.M12_delay = finddelay(obj.M12_irS1, obj.M12_irS2); 

            [obj.M21_c, obj.M21_lags] = xcorr(obj.M21_irS2, obj.M21_irS1,40,'coeff');
            obj.M21_delay = finddelay(obj.M21_irS1, obj.M21_irS2); 

            [obj.M12_H1ir, obj.M12_freq] = freqz(obj.M12_irS1, 1, obj.nfft, obj.fs); 
            obj.M12_H2ir = freqz(obj.M12_irS2, 1, obj.nfft, obj.fs);  

            [obj.M21_H1ir, obj.M21_freq] = freqz(obj.M21_irS1, 1, obj.nfft, obj.fs); 
            obj.M21_H2ir = freqz(obj.M21_irS2, 1, obj.nfft, obj.fs);  
        end


        function calc_R_ALPHA_Z(obj)

            obj.M12_H12ir = obj.M12_H2ir ./ obj.M12_H1ir; 
            obj.M21_H12ir = obj.M21_H2ir ./ obj.M21_H1ir; 
            obj.H12ir_AVG = sqrt(obj.M12_H12ir .* obj.M21_H12ir);
            obj.H12ir_AVG = abs(obj.H12ir_AVG).*exp(1i * (mod(angle(obj.H12ir_AVG), -pi)));

            obj.kIR = 2*pi.*obj.M12_freq/obj.c0; 
            obj.hiIR = exp(-1*1i*obj.kIR*obj.s1); 
            obj.hrIR = exp(1*1i*obj.kIR*obj.s1);

            %reflection factor (R)
            obj.M12_rIR = (obj.M12_H12ir - obj.hiIR) ./ (obj.hrIR - obj.M12_H12ir) .* exp(2*1i*obj.kIR*obj.z1);
            obj.M21_rIR = (obj.M21_H12ir - obj.hiIR) ./ (obj.hrIR - obj.M21_H12ir) .* exp(2*1i*obj.kIR*obj.z1);
            obj.rIR_AVG = (obj.H12ir_AVG - obj.hiIR) ./ (obj.hrIR - obj.H12ir_AVG) .* exp(2*1i*obj.kIR*obj.z1);

            %Absorption Coefficient (alpha)
            obj.M12_alphaIR = 1 - abs(obj.M12_rIR).^2;  
            obj.M21_alphaIR = 1 - abs(obj.M21_rIR).^2; 
            obj.alphaIR_AVG = 1 - abs(obj.rIR_AVG).^2; 

            %Specific Characteristic Impedance (Z)
            obj.M12_Z = ((1+obj.M12_rIR)./(1 - obj.M12_rIR)) * obj.rho*obj.c0;
            obj.M21_Z = ((1+obj.M21_rIR)./(1 - obj.M21_rIR)) * obj.rho*obj.c0;
            obj.Z_AVG = ((1+obj.rIR_AVG)./(1 - obj.rIR_AVG)) * obj.rho*obj.c0;

            %Complex Wavenumber 
            obj.M12_kw = (1*1i/2*obj.sample_th)*log((obj.rho*obj.c0+obj.M12_Z)./(obj.rho*obj.c0-obj.M12_Z));
            obj.M21_kw = (1*1i/2*obj.sample_th)*log((obj.rho*obj.c0+obj.M21_Z)./(obj.rho*obj.c0-obj.M21_Z));
            obj.kw_AVG = (1*1i/2*obj.sample_th)*log((obj.rho*obj.c0+obj.Z_AVG)./(obj.rho*obj.c0-obj.Z_AVG));

        end

        function LOAD_MAT_FILE(obj)

            [obj.filename, pathname] = uigetfile; 
            matfile = fullfile(pathname, obj.filename); 
            data = load(matfile);

            obj.excitation = data.excitation; 
            obj.fs = data.fs; 
            obj.M12_data_ch1_Pa = data.M12.data_ch1_Pa; 
            obj.M12_data_ch2_Pa = data.M12.data_ch2_Pa; 
            obj.M21_data_ch1_Pa = data.M21.data_ch1_Pa; 
            obj.M21_data_ch2_Pa = data.M21.data_ch2_Pa; 
            obj.mic1_sensitivity = data.mic1_sensitivity; 
            obj.mic2_sensitivity = data.mic2_sensitivity; 
            obj.t = data.t; 

            set_global_variables(obj);
            create_IR(obj);
            calc_R_ALPHA_Z(obj);
            
        end

        function SAVE_MAT_FILE(obj, title)


            title_full = title + ".mat";
            excitation = obj.excitation; %#ok<*PROPLC>
            fs = obj.fs;
            M12.data_ch1_Pa = obj.M12_data_ch1_Pa;
            M12.data_ch2_Pa = obj.M12_data_ch2_Pa;
            M21.data_ch1_Pa = obj.M21_data_ch1_Pa;
            M21.data_ch2_Pa = obj.M21_data_ch2_Pa;
            mic1_sensitivity = obj.mic1_sensitivity;
            mic2_sensitivity = obj.mic2_sensitivity;
            t = obj.t;
                
            save(title_full, 'excitation', 'fs', "M12", "M21", ...
                'mic1_sensitivity', 'mic2_sensitivity', 't');

        end
        
        
        

        function plot_absorption_coeff_figure(obj, figure, display_name)
            plot(figure, obj.M12_freq, obj.M12_alphaIR, 'DisplayName', display_name);
            title(figure, 'Absorption Coefficient IR')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'Alpha');
            xlim(figure, [500 5000])
            ylim(figure, [0 1]) 
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_reflection_factor_figure(obj, figure, display_name)
            plot(figure, obj.M12_freq, abs(obj.M12_rIR), 'DisplayName', display_name);
            title(figure,'Reflection Factor IR')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'Reflection Factor');
            xlim(figure,[500 5000])
            ylim(figure,[0 2])
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_complex_surface_impedance_figure(obj, figure, display_name)
            plot(figure,obj.M12_freq, abs(obj.M12_Z), 'DisplayName', display_name);
            title(figure,'Complex Surface Impedance |Z|')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'C.S.I');
            xlim(figure,[500 5000])
            ylim(figure,[0 6000])
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_complex_surface_impedance_phase_figure(obj, figure, display_name)
            plot(figure,obj.M12_freq, angle(obj.M12_Z), 'DisplayName', display_name);
            title(figure,'Complex Surface Impedance Phase')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'C.S.I.P');
            xlim(figure,[500 5000])
            ylim(figure,[-2 4])
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_complex_wavenumber_figure(obj, figure, display_name)
            plot(figure,obj.M12_freq,abs(obj.M12_kw), 'DisplayName', display_name);
            title(figure,'Complex Wavenumber |k(w)|')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'Complex Wavenumber');
            xlim(figure,[500 5000])
            ylim(figure,[0 1])
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_complex_wavenumber_figure_phase(obj, figure, display_name)
            plot(figure, obj.M12_freq,angle(obj.M12_kw), 'DisplayName', display_name);
            title(figure, 'Complex Wavenumber Phase(rad)')
            xlabel(figure, 'Frequency (Hz)');
            ylabel(figure, 'Complex Wavenumber Phase');
            xlim(figure,[500 5000])
            ylim(figure,[0 4])
            legend(figure);
            set(figure, 'XScale', 'log')
        end

        function plot_M12_Pressure_data_ch1(obj, figure, display_name)
            plot(figure, obj.t, obj.M12_data_ch1_Pa, 'DisplayName', display_name);
            title(figure, 'M12 Pressure Data - Channel 1')
            xlabel(figure, 'Time');
            ylabel(figure, 'Pressure (Pa)');
            xlim(figure,[0 10])
            ylim(figure,[0 5])
            legend(figure);
            set(figure, 'XScale', 'lin')
            
        end

        function plot_M12_Pressure_data_ch2(obj, figure, display_name)
            plot(figure, obj.t, obj.M12_data_ch2_Pa, 'DisplayName', display_name);
            title(figure, 'M12 Pressure Data - Channel 2')
            xlabel(figure, 'Time');
            ylabel(figure, 'Pressure (Pa)');
            xlim(figure,[0 10])
            ylim(figure,[0 5])
            legend(figure);
            set(figure, 'XScale', 'lin')
        end

        function plot_M21_Pressure_data_ch1(obj, figure, display_name)
            plot(figure, obj.t, obj.M21_data_ch1_Pa, 'DisplayName', display_name);
            title(figure, 'M21 Pressure Data - Channel 1')
            xlabel(figure, 'Time');
            ylabel(figure, 'Pressure (Pa)');
            xlim(figure,[0 10])
            ylim(figure,[0 5])
            legend(figure);
            set(figure, 'XScale', 'lin')
        end

        function plot_M21_Pressure_data_ch2(obj, figure, display_name)
            plot(figure, obj.t, obj.M21_data_ch2_Pa, 'DisplayName', display_name);
            title(figure, 'M21 Pressure Data - Channel 2')
            xlabel(figure, 'Time');
            ylabel(figure, 'Pressure (Pa)');
            xlim(figure,[0 10])
            ylim(figure,[0 5])
            legend(figure);
            set(figure, 'XScale', 'lin')

        end

    end


end
