# encoding: UTF-8
require_relative 'engine_test_helper'

class CalendarExportTest < EngineIntegrationTest

  should "output calendars correctly" do
    visit "/calendars-sample/y/2012-01-01/2012-05-01/yes"

    within '.result-info' do
      assert page.has_link? "Add dates to your calendar"
    end

    click_on "Add dates to your calendar"
    assert_calendar_has_event Date.parse("2012-01-01"), Date.parse("2012-05-01")
  end

  should "not render a calendar if one is not present" do
    visit "/calendars-sample/y/2012-01-01/2012-05-01/no"

    within '.result-info' do
      assert ! page.has_link?("Add dates to your calendar")
    end
  end

  should "return a 404 status when loading a calendar if none present" do
    visit "/calendars-sample/y/2012-01-01/2012-05-01/no.ics"

    assert_equal 404, page.status_code
  end

  should "not store the calendar in memory" do
    FLOW_REGISTRY_OPTIONS[:preload_flows] = true
    SmartAnswer::FlowRegistry.reset_instance

    visit "/calendars-sample/y/2012-01-01/2012-05-01/yes.ics"
    assert_calendar_has_event Date.parse("2012-01-01"), Date.parse("2012-05-01")

    visit "/calendars-sample/y/2012-01-08/2012-05-08/yes.ics"
    assert_calendar_has_event Date.parse("2012-01-08"), Date.parse("2012-05-08")
    assert_calendar_has_no_event Date.parse("2012-01-01"), Date.parse("2012-05-01")

    FLOW_REGISTRY_OPTIONS[:preload_flows] = false
    SmartAnswer::FlowRegistry.reset_instance
  end

  def assert_calendar_has_event(start_date, stop_date = nil)
    assert_match build_expression_for_dates(start_date, stop_date), page.body
  end

  def assert_calendar_has_no_event(start_date, stop_date = nil)
    assert_no_match build_expression_for_dates(start_date, stop_date), page.body
  end

  def build_expression_for_dates(start_date, stop_date)
    stop_date = start_date if stop_date.nil?
    stop_date = stop_date + 1.day

    %r{DTEND;VALUE=DATE:#{stop_date.strftime('%Y%m%d')}\r\nDTSTART;VALUE=DATE:#{start_date.strftime('%Y%m%d')}}
  end
end
