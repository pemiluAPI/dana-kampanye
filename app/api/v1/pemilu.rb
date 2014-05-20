module CampaignFinanceHelpers
  
  def get_all_by_calon_and_periode(campaignfinance, periode, field)
    campaignfinances = CampaignFinance.select("#{field}").where("calon_id = ? and nama = ?", campaignfinance.calon_id, campaignfinance.nama)
    campaignfinances = campaignfinances.where("periode in (?)", periode) unless periode.nil?
    campaignfinances
  end
  
  def sum_uang(campaignfinance, periode, uang)
    cfinance = get_all_by_calon_and_periode(campaignfinance, periode, uang)
    cfinance.sum(:uang)
  end
  
  def sum_nilai_barang(campaignfinance, periode, nilai_barang)
    cfinance = get_all_by_calon_and_periode(campaignfinance, periode, nilai_barang)
    cfinance.sum(:nilai_barang)
  end
  
  def sum_jumlah(campaignfinance, periode, jumlah)
    cfinance = get_all_by_calon_and_periode(campaignfinance, periode, jumlah)
    cfinance.sum(:jumlah)
  end
  
  def sum_nilai_jasa(campaignfinance, periode, nilai_jasa)
    cfinance = get_all_by_calon_and_periode(campaignfinance, periode, nilai_jasa)
    cfinance.sum(:nilai_jasa)
  end
  
  def calculate_periode(campaignfinance, period, periode)
    periods = Array.new
    cfinance = get_all_by_calon_and_periode(campaignfinance, period, periode)
    cfinance.each do |data|
      periods << data.periode
    end
    periods
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
        periods = params[:periode].split(',') unless params[:periode].nil?
        
        # Prepare conditions based on params
        valid_params = {
          lembaga: 'lembaga',
          partai: 'partai_id',
          role: 'roles.nama_pendek'
        }
        conditions = Hash.new
        valid_params.each_pair do |key, value|
          conditions[value.to_sym] = params[key.to_sym] unless params[key.to_sym].blank?
        end

        # Set default limit
        limit = (params[:limit].to_i == 0 || params[:limit].empty?) ? 2000 : params[:limit]
        
        search = params[:periode].nil? ? ["nama LIKE ?", "%#{params[:nama]}%"] : ["nama LIKE ? and periode in (?)", "%#{params[:nama]}%", periods]

        cfinances = CampaignFinance.includes(:role)
                                  .where(conditions)
                                  .where(search)
                                  .limit(limit)
                                  .offset(params[:offset])
                                  .group(:calon_id, :nama)
                                  .order(:id)
        unless periods.nil?
          cfinances.each do |campaignfinance|
            periode = periods.count < 2 ? campaignfinance.periode : calculate_periode(campaignfinance, periods, 'periode')
            uang = periods.count < 2 ? campaignfinance.uang : sum_uang(campaignfinance, periods, 'uang')
            nilai_barang = periods.count < 2 ? campaignfinance.nilai_barang : sum_nilai_barang(campaignfinance, periods, 'nilai_barang')
            nilai_jasa = periods.count < 2 ? campaignfinance.nilai_jasa : sum_nilai_jasa(campaignfinance, periods, 'nilai_jasa')
            jumlah = periods.count < 2 ? campaignfinance.jumlah : sum_jumlah(campaignfinance, periods, 'jumlah')
            contributions << {
              periode: periode,
              partai: {
                id: campaignfinance.partai_id,
                nama: campaignfinance.nama_partai
              },
              role: campaignfinance.role.nama_lengkap,
              nama: campaignfinance.nama,
              id_calon: campaignfinance.calon_id,
              mata_uang: campaignfinance.mata_uang,
              uang: uang,
              nilai_barang: nilai_barang,
              unit_barang: campaignfinance.unit_barang,
              nilai_jasa: nilai_jasa,
              bentuk_jasa: campaignfinance.bentuk_jasa,
              jumlah: jumlah,
              keterangan: campaignfinance.keterangan
            }
          end
        else
          cfinances.each do |campaignfinance|
            contributions << {
              periode: calculate_periode(campaignfinance, periods, 'periode'),
              partai: {
                id: campaignfinance.partai_id,
                nama: campaignfinance.nama_partai
              },
              role: campaignfinance.role.nama_lengkap,
              nama: campaignfinance.nama,
              id_calon: campaignfinance.calon_id,
              mata_uang: campaignfinance.mata_uang,
              uang: sum_uang(campaignfinance, periods, 'uang'),
              nilai_barang: sum_nilai_barang(campaignfinance, periods, 'nilai_barang'),
              unit_barang: campaignfinance.unit_barang,
              nilai_jasa: sum_nilai_jasa(campaignfinance, periods, 'nilai_jasa'),
              bentuk_jasa: campaignfinance.bentuk_jasa,
              jumlah: sum_jumlah(campaignfinance, periods, 'jumlah'),
              keterangan: campaignfinance.keterangan
            }
          end
        end
        {
          results: {
            count: contributions.count,
            total: CampaignFinance.includes(:role).where(conditions).where(search).group(:calon_id, :nama).count.count,
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
          periods = params[:periode].split(',') unless params[:periode].nil?
          campaignfinance = CampaignFinance.where("calon_id = ?", params[:id])
          campaignfinance = campaignfinance.where("periode in (?)", periods) unless params[:periode].nil?
          campaignfinance = campaignfinance.first
          unless periods.nil?
            periode = periods.count < 2 ? campaignfinance.periode : calculate_periode(campaignfinance, periods, 'periode')
            uang = periods.count < 2 ? campaignfinance.uang : sum_uang(campaignfinance, periods, 'uang')
            nilai_barang = periods.count < 2 ? campaignfinance.nilai_barang : sum_nilai_barang(campaignfinance, periods, 'nilai_barang')
            nilai_jasa = periods.count < 2 ? campaignfinance.nilai_jasa : sum_nilai_jasa(campaignfinance, periods, 'nilai_jasa')
            jumlah = periods.count < 2 ? campaignfinance.jumlah : sum_jumlah(campaignfinance, periods, 'jumlah')
            {
              results: {
                count: 1,
                total: 1,
                contributions: [{
                  periode: periode,
                  partai: {
                    id: campaignfinance.partai_id,
                    nama: campaignfinance.nama_partai
                  },
                  role: campaignfinance.role.nama_lengkap,
                  nama: campaignfinance.nama,
                  id_calon: campaignfinance.calon_id,
                  mata_uang: campaignfinance.mata_uang,
                  uang: uang,
                  nilai_barang: nilai_barang,
                  unit_barang: campaignfinance.unit_barang,
                  nilai_jasa: nilai_jasa,
                  bentuk_jasa: campaignfinance.bentuk_jasa,
                  jumlah: jumlah,
                  keterangan: campaignfinance.keterangan
                }]
              }
            }
          else
            {
              results: {
                count: 1,
                total: 1,
                contributions: [{
                  periode: calculate_periode(campaignfinance, periods, 'periode'),
                  partai: {
                    id: campaignfinance.partai_id,
                    nama: campaignfinance.nama_partai
                  },
                  role: campaignfinance.role.nama_lengkap,
                  nama: campaignfinance.nama,
                  id_calon: campaignfinance.calon_id,
                  mata_uang: campaignfinance.mata_uang,
                  uang: sum_uang(campaignfinance, periods, 'uang'),
                  nilai_barang: sum_nilai_barang(campaignfinance, periods, 'nilai_barang'),
                  unit_barang: campaignfinance.unit_barang,
                  nilai_jasa: sum_nilai_jasa(campaignfinance, periods, 'nilai_jasa'),
                  bentuk_jasa: campaignfinance.bentuk_jasa,
                  jumlah: sum_jumlah(campaignfinance, periods, 'jumlah'),
                  keterangan: campaignfinance.keterangan
                }]
              }
            }
          end
        end
      end
    end
  end
end