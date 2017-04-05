%%% WLAN CTMC Analysis
%%% Author: Sergio Barrachina (sergio.barrachina@upf.edu)
%%% File description: function for finding the probability of WLANs to tranmsit successfully in any number of channels

function [ prob_tx_in_num_channels_success, prob_tx_in_num_channels_unsuccess ] = get_probability_tx_in_n_channels( Power_PSI_cell, S_cell, PSI_cell, ...
        num_wlans, num_channels_system, p_equilibrium, path_loss_model,  distance_ap_sta, wlans )
    %GET_PROBABILITY_TX_IN_N_CHANNELS returns the probability of transmitting in a given number of channels
    % Input:
    %   - Power_PSI_cell: power sensed by every wlan in every channel in every global state [dBm]
    %   - PSI_cell: cell array representing the global states
    %   - S_cell: cell array representing the feasible states
    %   - num_wlans: number of WLANs in the system
    %   - num_channels_system:  number of channels in the system
    %   - p_equilibrium: equilibrium distribution array (pi)
    %   - path_loss_model: path loss model
    %   - distance_ap_sta: distance between the AP and STAs of a WLAN
    %   - wlans: array of structures with wlans info
    % Output:
    %   - prob_tx_in_num_channels: array whose element w,n is the probability of WLAN w of transmiting in n channels
   
    load('constants.mat');  % Load constants into workspace
    
    S_num_states = length(S_cell);  % Number of feasible states

    prob_tx_in_num_channels_success = zeros(num_wlans, num_channels_system + 1);    
    
    prob_tx_in_num_channels_unsuccess = zeros(num_wlans, num_channels_system + 1); 

    for s_ix = 1 : S_num_states
        
        disp(['- state: ' num2str(s_ix)])
        
        pi_s = p_equilibrium(s_ix); % probability of being in state s

        for wlan_ix = 1 : num_wlans
            
            disp(['  � wlan: ' num2str(wlan_ix)])
            
            % Number of channels used by WLAN wlan in state s
            [left_ch, right_ch, is_wlan_active ,num_channels] = get_channel_range(S_cell{s_ix}(wlan_ix,:));
            
            capture_effect_accomplished = true;    % Flag identifying if power sensed in evaluated range < CCA

            if is_wlan_active
                
                % CCA must be accomplished in every transmission channel
                for ch_ix =  left_ch : right_ch
                    
                    % Power sensed in channel ch
                    
                    [ ~, psi_s_ix ] = find_state_in_set( S_cell{s_ix}, PSI_cell );
                    
                    interest_power_mw = 10^(compute_power_received(distance_ap_sta, wlans(wlan_ix).tx_power, GAIN_TX_DEFAULT,...
                        GAIN_RX_DEFAULT, FREQUENCY, path_loss_model)/10);
          
                    interference_power_mw = 10^(Power_PSI_cell{psi_s_ix}(wlan_ix,ch_ix)/10);
                    
                    noise_power_mw = 10^(NOISE_DBM/10);
                    
                    sinr_linear = interest_power_mw / (interference_power_mw + noise_power_mw);
                    
                    sinr_db = 10 * log10(sinr_linear);
                    
                    disp(['    * sinr(ch = ' num2str(ch_ix) ') = ' num2str(sinr_db)])
                    
                    if sinr_db < CAPTURE_EFFECT
                        capture_effect_accomplished = false;
                    end
                end

                if capture_effect_accomplished
                    prob_tx_in_num_channels_success(wlan_ix, num_channels + 1) = prob_tx_in_num_channels_success(wlan_ix, num_channels + 1)...
                    + pi_s;
                else
                    prob_tx_in_num_channels_unsuccess(wlan_ix, num_channels + 1) = prob_tx_in_num_channels_unsuccess(wlan_ix, num_channels + 1)...
                    + pi_s;
                end
            end            
        end
    end
end

