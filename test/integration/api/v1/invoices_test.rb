# frozen_string_literal: true

require "openapi_helper"

module Api
  module V1
    class InvoicesTest < ActionDispatch::IntegrationTest
      include OpenapiRuby::Adapters::Minitest::DSL

      openapi_schema :"v1/schema"

      api_path "/invoices" do
        get("Invoices list") do
          operationId "invoices"
          tags "Invoices"
          produces "application/json"

          parameter "$ref": "#/components/parameters/PageParameter"
          parameter "$ref": "#/components/parameters/PerPageParameter"
          parameter name: "state", in: :query, required: false,
            schema: {type: :string, enum: %w[created charged paid]}
          parameter name: "year", in: :query, required: false, schema: {type: :integer}
          parameter name: "quarter", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 4}
          parameter name: "month", in: :query, required: false, schema: {type: :integer, minimum: 1, maximum: 12}
          parameter name: "paid_in_year", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_quarter", in: :query, required: false, schema: {type: :integer}
          parameter name: "paid_in_month", in: :query, required: false, schema: {type: :integer}
          parameter name: "project_id", in: :query, required: false,
            description: "Only what belongs to this project, which is what its own screen lists.",
            schema: {type: :string, format: :uuid}
          parameter name: "sort", in: :query, required: false,
            description: "Column to order by. Anything else falls back to the newest first.",
            schema: {type: :string, enum: %w[ref date value state customer]}
          parameter name: "direction", in: :query, required: false,
            schema: {type: :string, enum: %w[asc desc]}

          response(200, "successful") do
            schema ::V1::Schemas::Invoices
            header "Link", schema: {type: :string}, description: "RFC 8288 pagination links."
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end

        post("Create new Invoice") do
          operationId "createInvoice"
          tags "Invoices"
          consumes "application/json"
          produces "application/json"

          request_body required: true, content: {
            "application/json" => {schema: ::V1::Schemas::Inputs::InvoiceInput}
          }

          response(201, "successful") do
            schema ::V1::Schemas::Invoice
          end

          response(400, "bad request") do
            schema ::V1::Schemas::ValidationError
          end

          response(401, "unauthorized") do
            schema ::V1::Schemas::StandardError
          end
        end
      end

      let(:data) { users :data }
      let(:invoice) { invoices :january }
      let(:project) { projects :narendra3 }

      # `before_save :set_value` recomputes the column from the positions, so
      # a value passed to `create!` is thrown away — it goes in past the
      # callback. `ref` is unique per account, hence the running number.
      def invoice_worth(value)
        invoice = accounts(:enterprise).invoices.create!(
          customer: customers(:starfleet), project: projects(:narendra3),
          date: Date.new(2026, 3, 1), ref: accounts(:enterprise).invoices.maximum(:ref).to_i + 1
        )
        invoice.update_columns(value: value)
        invoice
      end

      describe "unauthorized" do
        it "does not list invoices" do
          assert_api_response :get, 401
        end
      end

      describe "signed in" do
        before { sign_in data }

        it "lists the account's invoices with their positions" do
          assert_api_response :get, 200 do
            listed = parsed_body.find { |item| item["id"] == invoice.id }

            assert listed, "expected invoice #{invoice.ref} in the list"
            assert_kind_of Array, listed["positions"]
          end
        end

        # The february fixture belongs to the defiant account.
        it "does not leak another account's invoices" do
          assert_api_response :get, 200 do
            refute_includes parsed_body.map { |item| item["id"] }, invoices(:february).id
          end
        end

        # The server-rendered list sorted by five columns; the endpoint only
        # ever answered newest-first.
        it "sorts by the columns the list offers" do
          cheap = invoice_worth(10)
          dear = invoice_worth(5000)

          assert_api_response :get, 200, params: {sort: "value", direction: "asc"} do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(cheap.id), :<, ids.index(dear.id)
          end

          assert_api_response :get, 200, params: {sort: "value", direction: "desc"} do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(dear.id), :<, ids.index(cheap.id)
          end
        end

        # Values, dates, states and customer names all repeat, and offset
        # paging over a tie can show a row twice or skip it. `ref` closes the
        # order so nothing is left undecided.
        it "breaks ties by ref so paging cannot repeat a row" do
          first = invoice_worth(100)
          second = invoice_worth(100)

          assert_api_response :get, 200, params: {sort: "value", direction: "asc"} do
            tied = parsed_body.select { |item| item["value"] == "100.0" }.map { |item| item["id"] }

            assert_equal [second.id, first.id], tied & [second.id, first.id]
          end
        end

        # Without a sort it stays what it always was: newest ref first.
        it "falls back to the newest first" do
          low = invoice_worth(10)
          high = invoice_worth(20)

          assert_api_response :get, 200 do
            ids = parsed_body.map { |item| item["id"] }

            assert_operator ids.index(high.id), :<, ids.index(low.id)
          end
        end

        it "filters by state" do
          assert_api_response :get, 200, params: {state: "paid"} do
            refute_includes parsed_body.map { |item| item["id"] }, invoice.id
          end
        end

        # The project screen lists what belongs to the project it shows.
        it "lists only what belongs to a project when asked" do
          other = projects(:outpost6)
          mine = data.account.invoices.create!(
            customer: customers(:starfleet), project: other, date: Date.new(2026, 5, 1),
            ref: data.account.invoices.maximum(:ref).to_i + 1
          )

          assert_api_response :get, 200, params: {project_id: other.id} do
            ids = parsed_body.map { |item| item["id"] }

            assert_includes ids, mine.id
            assert_equal [other.id], parsed_body.map { |item| item["projectId"] }.uniq
          end
        end

        it "creates an invoice with positions" do
          assert_api_response :post, 201, body: {
            project_id: project.id,
            date: "2026-08-01",
            positions_attributes: [{description: "Consulting", hours: "10.0", rate: "100.0"}]
          } do
            assert_equal 1, parsed_body["positions"].size
            # value is derived from hours x rate.
            assert_equal "1000.0", parsed_body["value"]
          end
        end

        # The invoice carries the account's address as the sender. The ERB
        # `new` action refused to render without one; going straight to the
        # API used to skip that guard entirely.
        it "refuses an invoice from an account with no address" do
          accounts(:enterprise).update!(address: nil)

          assert_api_response :post, 400, body: {
            project_id: project.id,
            date: "2026-08-01",
            positions_attributes: [{description: "Consulting", hours: "10.0", rate: "100.0"}]
          }
        end

        # The invoice takes its customer and its rate from the project, so a
        # position built from another project's timers would bill that time to
        # the wrong customer at the wrong rate.
        it "refuses timers from another project" do
          assert_api_response :post, 400, body: {
            project_id: projects(:outpost6).id,
            date: "2026-08-01",
            positions_attributes: [
              {description: "Consulting", hours: "2.0", timer_ids: [timers(:twohours).id]}
            ]
          }
        end
      end
    end
  end
end
