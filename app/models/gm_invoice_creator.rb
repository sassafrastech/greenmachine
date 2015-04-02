class GmInvoiceCreator
  ITEM_IDS = {development: 17}
  INVOICE_NUM_LENGTH = 5

  attr_accessor :report, :access_token, :token, :secret, :company_id, :service

  delegate :project, :interval, to: :report

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}

    self.access_token = OAuth::AccessToken.new($qb_oauth_consumer, token, secret)
  end

  def create
    create_service

    # Given a Customer with ID=99 lets invoice them for an Item with ID=500
    invoice = Quickbooks::Model::Invoice.new
    invoice.customer_id = 97
    invoice.txn_date = Date.today
    invoice.doc_number = next_number

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

    service.create(invoice)
  end

  private

  def create_service
    self.service = Quickbooks::Service::Invoice.new
    service.company_id = company_id
    service.access_token = access_token
  end

  def next_number
    existing = service.query('SELECT Id, DocNumber FROM Invoice ORDER BY MetaData.CreateTime DESC')
    latest_num = existing.entries.first.doc_number
    (latest_num.to_i + 1).to_s.rjust(INVOICE_NUM_LENGTH, '0')
  end
end
