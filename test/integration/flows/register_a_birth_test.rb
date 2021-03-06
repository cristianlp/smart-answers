# encoding: UTF-8
require_relative '../../test_helper'
require_relative 'flow_test_helper'
require 'gds_api/test_helpers/worldwide'

class RegisterABirthTest < ActiveSupport::TestCase
  include FlowTestHelper
  include GdsApi::TestHelpers::Worldwide

  setup do
    @location_slugs = %w(afghanistan andorra australia barbados belize cameroon central-african-republic china el-salvador guatemala grenada hong-kong indonesia ireland iran laos libya maldives pakistan spain sri-lanka st-kitts-and-nevis sweden taiwan thailand turkey united-arab-emirates usa yemen)
    worldwide_api_has_locations(@location_slugs)
    setup_for_testing_flow 'register-a-birth'
  end

  setup do
    setup_for_testing_flow 'register-a-birth'
  end

  should "ask which country the child was born in" do
    assert_current_node :country_of_birth?
  end

  context "answer Turkey" do
    setup do
      worldwide_api_has_organisations_for_location('turkey', read_fixture_file('worldwide/turkey_organisations.json'))
      add_response 'turkey'
    end
    should "ask which parent has british nationality" do
      assert_current_node :who_has_british_nationality?
    end
    context "answer mother" do
      setup do
        add_response 'mother'
      end
      should "ask if you are married or civil partnered" do
        assert_current_node :married_couple_or_civil_partnership?
      end
      context "answer no" do
        setup do
          add_response 'no'
        end
        should "ask where you are now and go to embassy result" do
          add_response "same_country"
          assert_current_node :embassy_result
        end
      end # not married/cp
    end # mother
  end # Turkey

  context "answer with a commonwealth country" do
    should "give the commonwealth result" do
      add_response 'australia'
      assert_current_node :commonwealth_result
    end
  end # commonweath result

  context "answer Andorra" do
    should "store the correct registration country" do
      worldwide_api_has_organisations_for_location('spain', read_fixture_file('worldwide/spain_organisations.json'))
      add_response 'andorra'
      add_response 'father'
      add_response 'yes'
      add_response 'same_country'
      assert_state_variable :registration_country, 'spain'
    end
  end # Andorra

  context "answer Iran" do
    should "give the no embassy outcome and be done" do
      worldwide_api_has_organisations_for_location('iran', read_fixture_file('worldwide/iran_organisations.json'))
      add_response 'iran'
      assert_current_node :no_embassy_result
    end
  end # Iran

  context "answer Spain" do
    setup do
      worldwide_api_has_organisations_for_location('spain', read_fixture_file('worldwide/spain_organisations.json'))
      add_response 'spain'
    end
    should "store this as the registration country" do
      assert_state_variable :registration_country, 'spain'
    end
    should "ask which parent has british nationality" do
      assert_current_node :who_has_british_nationality?
    end
    context "answer father" do
      setup do
        add_response 'father'
      end
      should "ask if you are married or civil partnered" do
        assert_current_node :married_couple_or_civil_partnership?
      end
      context "answer no" do
        setup do
          add_response 'no'
        end
        should "ask when the child was born" do
          assert_current_node :childs_date_of_birth?
        end
        context "answer pre 1st July 2006" do
          should "give the homeoffice result" do
            add_response '2006-06-30'
            assert_current_node :homeoffice_result
          end
        end
        context "answer on or after 1st July 2006" do
          setup do
            add_response '2006-07-01'
          end
          should "ask where you are now" do
            assert_current_node :where_are_you_now?
          end
        end
      end # not married/cp
    end # father is british citizen
    context "answer mother and father" do
      setup do
        add_response 'mother_and_father'
      end
      should "ask if you are married or civil partnered" do
        assert_current_node :married_couple_or_civil_partnership?
      end
      context "answer yes" do
        setup do
          add_response 'yes'
        end
        should "ask where you are now" do
          assert_current_node :where_are_you_now?
        end
        context "answer back in the UK" do
          should "give the fco result" do
            add_response 'in_the_uk'
            assert_state_variable :registration_country, 'spain'
            assert_current_node :fco_result
            assert_phrase_list :birth_registration_form, [:birth_registration_form]
            assert_phrase_list :intro, [:intro]
            assert_state_variable :embassy_high_commission_or_consulate, "British consulate general"
          end
        end
        context "answer in another country" do
          setup do
            add_response "another_country"
          end
          context "answer which country" do
            should "Ireland and get the commonwealth result" do 
              worldwide_api_has_organisations_for_location('ireland', read_fixture_file('worldwide/ireland_organisations.json'))
              add_response 'ireland'
              assert_state_variable :another_country, true
              assert_state_variable :registration_country, 'ireland'
              assert_phrase_list :birth_registration_form, [:birth_registration_form]
              assert_current_node :embassy_result
            end # now in Ireland
            should "USA and get the embassy outcome" do
              worldwide_api_has_organisations_for_location('usa', read_fixture_file('worldwide/usa_organisations.json'))
              add_response 'usa'
              assert_state_variable :embassy_high_commission_or_consulate, "British embassy"
              assert_state_variable :registration_country, "usa"
              assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_all]
              assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
              assert_phrase_list :go_to_the_embassy, [:registering_clickbook, :registering_either_parent]
              assert_state_variable :clickbook_data, 'http://www.britishembassydc.clickbook.net/'
              assert_state_variable :postal_form_url, nil
              assert_phrase_list :postal, [:postal_info, :"postal_info_usa"]
              assert_phrase_list :footnote, [:footnote_another_country]
              assert_current_node :embassy_result
            end # now in USA
            should "answer Yemen and get the no embassy outcome" do
              add_response 'yemen'
              assert_current_node :no_embassy_result
              assert_state_variable :registration_country_name, "Yemen"
            end # now in Yemen 
          end # in another country
        end # mother and father british citizens
      end # married
    end # Spain
  end
  context "answer Afghanistan" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('afghanistan', read_fixture_file('worldwide/afghanistan_organisations.json'))
      add_response "afghanistan"
      add_response "mother_and_father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :embassy_high_commission_or_consulate, "British embassy"
      assert_state_variable :registration_country_name, "Afghanistan"
      assert_state_variable :british_national_parent, 'mother_and_father'
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_all]
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :go_to_the_embassy, [:registering_all, :registering_either_parent]
      assert_state_variable :postal_form_url, nil 
      assert_state_variable :postal, ""
      assert_phrase_list :footnote, [:footnote_exceptions] 
    end
  end # Afghanistan
  context "answer Pakistan" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('pakistan', read_fixture_file('worldwide/pakistan_organisations.json'))
      add_response "pakistan"
      add_response "father"
      add_response "yes"
      add_response "in_the_uk"
      assert_current_node :embassy_result
    end
  end # Pakistan
  context "answer Sweden" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('sweden', read_fixture_file('worldwide/sweden_organisations.json'))
      add_response "sweden"
      add_response "father"
      add_response "no"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'mother_and_father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_sweden]
      assert_phrase_list :documents_footnote, [:docs_footnote_sweden]
    end
  end # Sweden
  context "answer Taiwan" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('taiwan', read_fixture_file('worldwide/taiwan_organisations.json'))
      add_response "taiwan"
      add_response "mother_and_father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'mother_and_father'
      assert_state_variable :embassy_high_commission_or_consulate, 'British Trade & Cultural Office'
      assert_phrase_list :cash_only, [:cheque_only]
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_taiwan]
    end
  end # Taiwan
  context "answer Taiwan now in the UK" do
    should "give the FCO result" do
      add_response "taiwan"
      add_response "mother_and_father"
      add_response "yes"
      add_response "in_the_uk"
      assert_current_node :fco_result
      assert_state_variable :intro, ''
      assert_state_variable :british_national_parent, 'mother_and_father'
    end
  end # Taiwan
  context "answer Central African Republic now in the UK" do
    should "give the FCO result" do
      add_response "central-african-republic"
      add_response "mother_and_father"
      add_response "yes"
      add_response "in_the_uk"
      assert_current_node :fco_result
      assert_state_variable :intro, ''
      assert_state_variable :british_national_parent, 'mother_and_father'
    end
  end # Central African Republic
  context "answer Belize" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('belize', read_fixture_file('worldwide/belize_organisations.json'))
      add_response "belize"
      add_response "father"
      add_response "no"
      add_response "2006-07-01"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_all]
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :go_to_the_embassy, [:registering_clickbook, :registering_paternity_declaration]
    end # Not married or CP
  end # Belize
  context "answer Libya" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('libya', read_fixture_file('worldwide/libya_organisations.json'))
      add_response "libya"
      add_response "father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees_libya]
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_libya]
      assert_phrase_list :go_to_the_embassy, [:registering_all, :registering_either_parent]
    end # Not married or CP
  end # Libya
  context "answer Hong Kong" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('hong-kong', read_fixture_file('worldwide/hong-kong_organisations.json'))
      add_response "hong-kong"
      add_response "father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_all]
      assert_phrase_list :go_to_the_embassy, [:registering_hong_kong, :registering_either_parent]
    end # Not married or CP
  end # Hong Kong
  context "answer barbados" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('barbados', read_fixture_file('worldwide/barbados_organisations.json'))
      add_response "barbados"
      add_response "father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :documents_you_must_provide, [:documents_you_must_provide_all]
      assert_phrase_list :go_to_the_embassy, [:registering_all, :registering_either_parent]
      assert_phrase_list :cash_only, [:cash_and_card]
      assert_phrase_list :footnote, [:footnote]
    end # Not married or CP
  end # Barbados
  context "answer united arab emirates" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('united-arab-emirates', read_fixture_file('worldwide/united-arab-emirates_organisations.json'))
      add_response "united-arab-emirates"
      add_response "father"
      add_response "yes"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :documents_you_must_provide, [:"documents_you_must_provide_united-arab-emirates"]
      assert_phrase_list :cash_only, [:cash_and_card]
      assert_phrase_list :footnote, [:footnote]
      assert_match /British Embassy Dubai/, outcome_body # there are two separate organisations in UAE so this tests that the correct embassy (Dubai) is returned
    end # Not married or CP
  end # UAE
  context "answer indonesia" do
    should "give the embassy result" do
      worldwide_api_has_organisations_for_location('indonesia', read_fixture_file('worldwide/indonesia_organisations.json'))
      add_response "indonesia"
      add_response "father"
      add_response "no"
      add_response "2007-06-05"
      add_response "same_country"
      assert_current_node :embassy_result
      assert_state_variable :british_national_parent, 'father'
      assert_phrase_list :fees_for_consular_services, [:consular_service_fees]
      assert_phrase_list :embassy_result_indonesia_british_father_paternity, [:indonesia_british_father_paternity]
      assert_phrase_list :documents_you_must_provide, [:"documents_you_must_provide_all"]
      assert_phrase_list :cash_only, [:cash_and_card]
      assert_phrase_list :footnote, [:footnote]
    end # Not married or CP
  end # Indonesia

  context "el-salvador, where you have to register in guatemala" do
    setup do
      worldwide_api_has_organisations_for_location('guatemala', read_fixture_file('worldwide/guatemala_organisations.json'))
      add_response "el-salvador"
    end

    should "calculate the registration country as Guatemala" do
      add_response 'father'
      add_response 'yes'
      add_response 'same_country'
      assert_state_variable :registration_country, "guatemala"
      assert_state_variable :registration_country_name, "Guatemala"
    end
  end

  context "laos, where you have to register in thailand" do
    setup do
      worldwide_api_has_organisations_for_location('thailand', read_fixture_file('worldwide/thailand_organisations.json'))
      add_response "laos"
    end
    should "calculate the registration country as Thailand" do
      add_response 'father'
      add_response 'yes'
      add_response 'same_country'
      assert_state_variable :registration_country, "thailand"
      assert_state_variable :registration_country_name, "Thailand"
    end
  end
  context "maldives, where you have to register in sri lanka" do
    setup do
      worldwide_api_has_organisations_for_location('sri-lanka', read_fixture_file('worldwide/sri-lanka_organisations.json'))
      add_response "maldives"
    end
    should "calculate the registration country as Sri Lanka" do
      add_response 'father'
      add_response 'yes'
      add_response 'same_country'
      assert_state_variable :registration_country, "sri-lanka"
      assert_state_variable :registration_country_name, "Sri Lanka"
    end
  end
  context "China" do
    should "render multiple clickbook links" do
      worldwide_api_has_organisations_for_location('china', read_fixture_file('worldwide/china_organisations.json'))
      add_response 'china'
      add_response 'mother'
      add_response 'yes'
      add_response 'same_country'
      assert_current_node :embassy_result
      assert outcome_body.at_css("ul li a[href='https://www.clickbook.net/dev/bc.nsf/sub/BritEmBeijing']")
    end
  end
  context "child born in grenada, parent in St kitts" do
    should "calculate the registration country as barbados" do
      worldwide_api_has_organisations_for_location('barbados', read_fixture_file('worldwide/barbados_organisations.json'))
      add_response 'grenada'
      add_response 'mother'
      add_response 'yes'
      add_response 'another_country'
      add_response 'st-kitts-and-nevis'
      assert_current_node :embassy_result
      assert_phrase_list :birth_registration_form, [:birth_registration_form]
    end
  end
  context "child born in usa, parent in usa" do
    should "give the embassy result with usa birth reg form" do
      worldwide_api_has_organisations_for_location('usa', read_fixture_file('worldwide/usa_organisations.json'))
      add_response 'usa'
      add_response 'father'
      add_response 'yes'
      add_response 'same_country'
      assert_current_node :embassy_result
      assert_phrase_list :birth_registration_form, [:birth_registration_form_usa]
    end
  end
  # testing for delivery return form in Spain
  context "child born in italy, parents in spain" do
    should "give the embassy result with italy delivery return form form" do
      worldwide_api_has_organisations_for_location('spain', read_fixture_file('worldwide/spain_organisations.json'))
      add_response 'spain'
      add_response 'mother_and_father'
      add_response 'yes'
      add_response 'same_country'
      assert_current_node :embassy_result
      assert_phrase_list :postal_return, [:postal_form_return]
      assert_phrase_list :birth_registration_form, [:birth_registration_form]
    end
  end

end
