class CardSender < AbstractSender

  # How to use:
  # sender = CardSender.new(user)
  # sender.add_card(title: 'Invite a friend!', image_url: 'http... or name of image in assets folder')
  #       .add_url_button(title: 'Invite!', url: 'http...', webview_size: 'tall')
  #       .add_share_button
  # sender.add_card(...)
  # sender.deliver!

  def initialize(user)
    super(user)
    @elements = []
  end

  def add_card(title: nil, subtitle: nil, item_url: nil, image_url: nil)
    element = {}
    element[:title] = AbstractSender.locale_message(title)
    element[:subtitle] = AbstractSender.locale_message(subtitle) if subtitle
    element[:item_url] = AbstractSender.url_for_page(item_url) if item_url
    element[:image_url] = AbstractSender.url_for_asset(image_url) if image_url
    @elements.append(element)

    def element.add_url_button(title: nil, url: nil, webview_size: nil,
                               use_extensions: false, fallback_url: nil,
                               as_default_action: false)
      raise StandardError('CardSender url button for element missing url') unless url
      raise StandardError("CardSender invalid value #{webview_size} for webview_size") unless [nil, 'compact', 'tall', 'full'].include?(webview_size)

      self[:buttons] = [] unless (self[:buttons] || as_default_action)
      button = {
        type: 'web_url',
        url: AbstractSender.url_for_page(url)
      }
      button[:title] = AbstractSender.locale_message(title) unless as_default_action
      button[:webview_height_ratio] = webview_size if webview_size
      button[:messenger_extensions] = use_extensions if use_extensions
      button[:fallback_url] = AbstractSender.url_for_page(fallback_url) if fallback_url
      if as_default_action
        self[:default_action] = button
      else
        self[:buttons].append(button)
      end
      self
    end

    def element.add_postback_button(title: nil, payload: nil)
      raise StandardError('CardSender postback button for element missing title or payload') unless title && payload
      self[:buttons] = [] unless self[:buttons]
      self[:buttons].append({
        type: 'postback',
        title: AbstractSender.locale_message(title),
        payload: payload
      })
      self
    end

    def element.add_share_button
      self[:buttons] = [] unless self[:buttons]
      self[:buttons].append({
        type: 'element_share'
      })
      self
    end

    element
  end

  def deliver
    @data = {
      message: {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: @elements
          }
        }
      }
    }
    super
  end
end