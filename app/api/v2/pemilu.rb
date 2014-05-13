module CampaignFinanceHelpers
  
  def sum_uang(campaignfinance, periode)
    campaignfinances = CampaignFinance.select("uang").where("calon_id = ?", campaignfinance.calon_id)
    campaignfinances = campaignfinances.where("periode in (#{periode})") unless periode.nil?
    campaignfinances.sum(:uang)
  end
  
  def sum_jumlah(campaignfinance, periode)
    campaignfinances = CampaignFinance.select("jumlah").where("calon_id = ?", campaignfinance.calon_id)
    campaignfinances = campaignfinances.where("periode in (#{periode})") unless periode.nil?
    campaignfinances.sum(:jumlah)
  end
  
  def sum_nilai_jasa(campaignfinance, periode)
    campaignfinances = CampaignFinance.select("nilai_jasa").where("calon_id = ?", campaignfinance.calon_id)
    campaignfinances = campaignfinances.where("periode in (#{periode})") unless periode.nil?
    campaignfinances.sum(:nilai_jasa)
  end
  
  def calculate_periode(campaignfinance, periode)
    periods = Array.new
    campaignfinances = CampaignFinance.select("periode").where("calon_id = ?", campaignfinance.calon_id)
    campaignfinances = campaignfinances.where("periode in (#{periode})") unless periode.nil?
    campaignfinances.each do |data|
      periods << data.periode
    end
    periods
  end
  
  def get_partai(partai_id)
    encode_partai_url  = URI.encode("#{Rails.configuration.pemilu_api_endpoint}/api/partai/#{partai_id}?apiKey=#{Rails.configuration.pemilu_api_key}")
    partai_end = HTTParty.get(encode_partai_url, timeout: 500)
    partai = partai_end.parsed_response['data']['results']['partai'].first
    partai
  end
end

module Pemilu
  class APIv1 < Grape::API
    version 'v1', using: :accept_version_header
    prefix 'api'
    format :json

    resource :contributions do
      helpers CampaignFinanceHelpers
      
      desc "Return all Campaign Finances"      
      get do        
        contributions = Array.new

        # Prepare conditions based on params
        valid_params = {
          lembaga: 'lembaga',
          partai: 'partai_id',          
          role: 'role_id',
          periode: 'periode'
        }
        conditions = Hash.new
        valid_params.each_pair do |key, value|
          conditions[value.to_sym] = params[key.to_sym] unless params[key.to_sym].blank?
        end

        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 2000 : params[:limit]
        
        search = ["nama LIKE ?", "%#{params[:nama]}%"]        
        
        cfinances = CampaignFinance.includes(:role)         
                                  .where(conditions)
                                  .where(search)
                                  .limit(limit)
                                  .offset(params[:offset])
                                  .group(:calon_id, :nama)
                                  .order(:calon_id)
                                  
        cfinances.each do |campaignfinance|
            contributions << {
              periode: calculate_periode(campaignfinance, params[:periode]),
              partai: {
                id: get_partai(campaignfinance.partai_id)["id"],
                nama: get_partai(campaignfinance.partai_id)["nama"]
              },
              role: campaignfinance.role,
              nama: campaignfinance.nama,
              id_calon: campaignfinance.calon_id,
              mata_uang: campaignfinance.mata_uang,
              uang: sum_uang(campaignfinance, params[:periode]),
              nilai_barang: campaignfinance.nilai_barang,
              unit_barang: campaignfinance.unit_barang,
              nilai_jasa: sum_nilai_jasa(campaignfinance, params[:periode]),
              bentuk_jasa: campaignfinance.bentuk_jasa,
              jumlah: sum_jumlah(campaignfinance, params[:periode]),
              keterangan: campaignfinance.keterangan
            }
        end
        {
          results: {
            count: contributions.count,
            total: CampaignFinance.where(conditions).count,
            contributions: contributions
          }
        }
      end
      
      desc "Return the Contributions for a single candidate"
      params do
        requires :id, type: String, desc: "Candidate ID."
      end
      route_param :id do
        helpers CampaignFinanceHelpers
        
        get do          
          campaignfinance = CampaignFinance.where("calon_id = ?", params[:id])
          campaignfinance = campaignfinance.where("periode in (#{params[:periode]})") unless params[:periode].nil?
          campaignfinance = campaignfinance.first
          {
            results: {
              count: 1,
              total: 1,
              contributions: [{
                periode: calculate_periode(campaignfinance, params[:periode]),
                partai: {
                  id: get_partai(campaignfinance.partai_id)["id"],
                  nama: get_partai(campaignfinance.partai_id)["nama"]
                },
                role: campaignfinance.role,
                nama: campaignfinance.nama,
                id_calon: campaignfinance.calon_id,
                mata_uang: campaignfinance.mata_uang,
                uang: sum_uang(campaignfinance, params[:periode]),
                nilai_barang: campaignfinance.nilai_barang,
                unit_barang: campaignfinance.unit_barang,
                nilai_jasa: sum_nilai_jasa(campaignfinance, params[:periode]),
                bentuk_jasa: campaignfinance.bentuk_jasa,
                jumlah: sum_jumlah(campaignfinance, params[:periode]),
                keterangan: campaignfinance.keterangan
              }]
            }
          }
        end
      end
    end    
  end
end