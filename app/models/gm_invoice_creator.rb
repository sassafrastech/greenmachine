class GmInvoiceCreator
  ITEM_IDS = {development: 17}

  attr_accessor :report, :access_token, :token, :secret, :company_id

  delegate :project, :interval, to: :report

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    self.access_token = OAuth::AccessToken.new($qb_oauth_consumer, token, secret)
  end

  def create
    # Given a Customer with ID=99 lets invoice them for an Item with ID=500
    invoice = Quickbooks::Model::Invoice.new
    invoice.customer_id = 97
    invoice.txn_date = Date.today
    invoice.doc_number = '' # Autogenerate

    report.totals.each do |user, hours|
      rate = user == :sassy ? project.gm_full_rate(interval).val : user.gm_project_rate(user, interval).val
      hours = hours.round(2)

      line_item = Quickbooks::Model::InvoiceLineItem.new
      line_item.amount = rate * hours
      line_item.description = user == :sassy ? 'Sassafras hours' : "#{user.name} hours"
      line_item.sales_item! do |detail|
        detail.unit_price = rate
        detail.quantity = hours
        detail.item_id = ITEM_IDS[:development]
      end
      invoice.line_items << line_item
    end

    service = Quickbooks::Service::Invoice.new
    service.company_id = company_id
    service.access_token = access_token
    service.create(invoice)
  end
end
