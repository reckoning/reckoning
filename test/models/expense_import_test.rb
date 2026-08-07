# frozen_string_literal: true

require "test_helper"

class ExpenseImportTest < ActiveSupport::TestCase
  FileStub = Struct.new(:path, :original_filename)

  def setup
    @account = accounts(:enterprise)
  end

  def import_for(content, attributes = {})
    @tempfile = Tempfile.new(["import", ".csv"])
    @tempfile.write(content)
    @tempfile.rewind
    stub = FileStub.new(@tempfile.path, "import.csv")
    ExpenseImport.new({file: stub, account_id: @account.id}.merge(attributes))
  end

  def teardown
    @tempfile&.close
    @tempfile&.unlink
  end

  # --- Step 1: parsing for the preview ---

  test "parses an ADAC bank statement, converting German date and amount" do
    csv = <<~CSV
      Date;Value date;Category;Name;Purpose;Account;Bank;Amount;Currency
      03.07.2025;03.07.2025;;Dnsimple, +18886947448;Originalbetrag: -9,20 USD;;;-7,96;EUR
    CSV

    expenses = import_for(csv, expense_type: "current", vat_percent: 19).preview_expenses

    assert_equal 1, expenses.size
    expense = expenses.first
    assert_equal Date.new(2025, 7, 3), expense.date
    assert_equal BigDecimal("7.96"), expense.value
    assert_equal "Dnsimple, +18886947448", expense.seller
    assert_equal "Originalbetrag: -9,20 USD", expense.description
    assert_equal "current", expense.expense_type
    assert_equal 19, expense.vat_percent
  end

  test "skips credits (positive amounts) by default when parsing" do
    csv = <<~CSV
      Date;Value date;Category;Name;Purpose;Account;Bank;Amount;Currency
      03.07.2025;03.07.2025;;Charge;buy;;;-7,96;EUR
      04.07.2025;04.07.2025;;Refund;credit;;;12,50;EUR
    CSV

    expenses = import_for(csv).preview_expenses

    assert_equal 1, expenses.size
    assert_equal BigDecimal("7.96"), expenses.first.value
  end

  test "keeps credits when skip_credits is disabled" do
    csv = <<~CSV
      Date;Value date;Category;Name;Purpose;Account;Bank;Amount;Currency
      04.07.2025;04.07.2025;;Refund;credit;;;12,50;EUR
    CSV

    expenses = import_for(csv, skip_credits: "0").preview_expenses

    assert_equal 1, expenses.size
    assert_equal BigDecimal("12.5"), expenses.first.value
  end

  test "parses the Reckoning round-trip CSV format" do
    csv = <<~CSV
      expense_type,value,description,date,seller,private_use_percent,vat_percent,interval
      licenses,10.00,Some tool,2025-01-15,ACME,0,19,once
    CSV

    expenses = import_for(csv).preview_expenses

    assert_equal 1, expenses.size
    assert_equal "licenses", expenses.first.expense_type
    assert_equal Date.new(2025, 1, 15), expenses.first.date
  end

  # --- Step 2: persisting the edited/selected rows ---

  test "persists selected rows with edited seller and description" do
    rows = [
      {include: "1", date: "2025-07-03", value: "7.96", seller: "Dnsimple (bearbeitet)",
       description: "DNS-Domain", expense_type: "licenses", vat_percent: "19", private_use_percent: "0", interval: "once"}
    ]
    import = ExpenseImport.new(account_id: @account.id, rows: rows)

    assert_difference -> { Expense.count }, 1 do
      assert import.save, import.errors.full_messages.to_sentence
    end

    expense = @account.expenses.order(:created_at).last
    assert_equal "Dnsimple (bearbeitet)", expense.seller
    assert_equal "DNS-Domain", expense.description
    assert_equal "licenses", expense.expense_type
    assert_equal BigDecimal("7.96"), expense.value
  end

  test "skips deselected rows on save" do
    rows = [
      {include: "1", date: "2025-07-03", value: "7.96", seller: "Keep", description: "keep",
       expense_type: "licenses", vat_percent: "19", private_use_percent: "0", interval: "once"},
      {include: "0", date: "2025-07-04", value: "6.38", seller: "Drop", description: "drop",
       expense_type: "licenses", vat_percent: "19", private_use_percent: "0", interval: "once"}
    ]
    import = ExpenseImport.new(account_id: @account.id, rows: rows)

    assert_difference -> { Expense.count }, 1 do
      assert import.save, import.errors.full_messages.to_sentence
    end
    assert_equal "Keep", @account.expenses.order(:created_at).last.seller
  end

  test "fails when no row is selected" do
    rows = [
      {include: "0", date: "2025-07-03", value: "7.96", seller: "Drop", description: "drop",
       expense_type: "licenses", vat_percent: "19", private_use_percent: "0", interval: "once"}
    ]
    import = ExpenseImport.new(account_id: @account.id, rows: rows)

    assert_no_difference -> { Expense.count } do
      assert_not import.save
    end
    assert_includes import.errors[:base], I18n.t(:"expenses.import.no_rows_selected")
  end

  test "preview_expenses is empty without a file" do
    assert_empty ExpenseImport.new(account_id: @account.id).preview_expenses
  end
end
