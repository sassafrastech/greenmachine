class GmInvoiceCreator
  ITEM_IDS = {development: 17, subcontracted_services: 26}
  INVOICE_NUM_LENGTH = 5
  NET_30_TERMS = 3

  attr_accessor :report, :credential, :services, :skip_nums

  delegate :project, :interval, to: :report

  def initialize(attribs = {})
    attribs.each{|k,v| instance_variable_set("@#{k}", v)}
    self.skip_nums = 0
  end

  def create
    create_services

    # Given a Customer with ID=99 lets invoice them for an Item with ID=500
    invoice = Quickbooks::Model::Invoice.new
    invoice.customer_id = project.gm_qb_customer_id || (raise "No customer ID.")

    # Last day of last month
    invoice.txn_date = Date.today - Date.today.day

    # This reflects net 30 terms since we don't actually send the invoice on the last day of the month.
    invoice.due_date = Date.today + 30.days

    invoice.sales_term_id = NET_30_TERMS
    invoice.billing_email_address = email_addresses

    report.totals.each do |user, hours|
      rate = user == :sassy ? project.gm_full_rate(interval).val : user.gm_project_rate(project, interval).val

      line_item = Quickbooks::Model::InvoiceLineItem.new
      line_item.amount = rate * hours
      line_item.description = "#{project.name}: "
      line_item.description << (user == :sassy ? 'Sassafras hours' : "#{user.name} hours")
      line_item.sales_item! do |detail|
        detail.unit_price = rate
        detail.quantity = hours
        detail.item_id = ITEM_IDS[user == :sassy ? :development : :subcontracted_services]
      end
      invoice.line_items << line_item
    end

    # Loop in case there are deleted invoices and we have to retry with a new number
    loop do
      begin
        invoice.doc_number = next_number
        created_invoice = services[:invoice].create(invoice) # May error
        attach_csv(created_invoice)
        break created_invoice
      rescue Quickbooks::IntuitRequestException => error
        if error.to_s.match("You must specify a different number. This number has already been used")
          self.skip_nums += 1
          raise if skip_nums >= 5
        else
          raise
        end
      end
    end
  end

  private

  def create_services
    self.services = {}
    services[:invoice] = Quickbooks::Service::Invoice.new
    services[:upload] = Quickbooks::Service::Upload.new
    services[:customer] = Quickbooks::Service::Customer.new

    services.values.each{ |s| credential.apply_to(s) }
  end

  def next_number
    existing = services[:invoice].query('SELECT Id, DocNumber FROM Invoice ORDER BY MetaData.CreateTime DESC')
    latest_num = existing.entries.first.doc_number
    (latest_num.to_i + 1 + skip_nums).to_s.rjust(INVOICE_NUM_LENGTH, '0')
  end

  def attach_csv(invoice)
    upload = Quickbooks::Model::Attachable.new
    upload.file_name = report.csv_filename
    upload.content_type = 'text/csv'

    # This bit is not quite working.
    # entity = Quickbooks::Model::EntityRef.new
    # entity.type = 'Invoice'
    # entity.value = invoice.id.to_s
    # upload.attachable_ref = Quickbooks::Model::AttachableRef.new(entity)

    tmp_file = File.join(Rails.root, 'tmp', "#{invoice.id}-timelog.csv")
    File.open(tmp_file, 'w'){ |f| f.write(report.to_csv) }

    services[:upload].upload(tmp_file, 'text/csv', upload)

    File.unlink(tmp_file)
  end

  def email_addresses
    # Get customer email
    customer = services[:customer].fetch_by_id(project.gm_qb_customer_id)
    main = (customer.primary_email_address.try(:address) || '').split(/\s*,\s*/)
    extra = (project.gm_extra_emails || '').split((/\s*,\s*/))
    (main + extra).join(', ')
  end
end
