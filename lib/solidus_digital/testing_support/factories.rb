# frozen_string_literal: true

FactoryBot.define do
  factory :digital, class: Spree::Digital do |f|
    f.variant { |p| p.association(:variant) }
    f.attachment { { io: StringIO.new('digital content'), filename: "#{SecureRandom.hex(5)}.epub", content_type: 'application/epub+zip' } }

    trait :drm do
      drm { true }
      attachment do
        pdf = Prawn::Document.new { text 'Cover'; start_new_page; text 'Chapter 1' }
        { io: StringIO.new(pdf.render), filename: 'book.pdf', content_type: 'application/pdf' }
      end
    end
  end

  factory :digital_link, class: Spree::DigitalLink do |f|
    f.digital { |p| p.association(:digital) }
    f.line_item { |p| p.association(:line_item) }
  end

  factory :digital_shipping_calculator, class: Spree::Calculator::Shipping::DigitalDelivery do
    after :create do |c|
      c.set_preference(:amount, 0)
    end
  end

  factory :digital_shipping_method, parent: :shipping_method do
    name { "Digital Delivery" }
    calculator { FactoryBot.build :digital_shipping_calculator }
  end
end
