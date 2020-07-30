{% if theme.busuanzi_count.total_visitors %}
	<span class="site-uv" title="{{ __('footer.total_visitors') }}">
	  <i class="fa fa-{{ theme.busuanzi_count.total_visitors_icon }}"></i>
	  <span class="busuanzi-value" id="busuanzi_value_site_uv"></span> people visited our site. |
	</span>
  {% endif %}

  {% if theme.busuanzi_count.total_views %}
	<span class="site-pv" title="{{ __('footer.total_views') }}">
	  &nbsp;<i class="fa fa-{{ theme.busuanzi_count.total_views_icon }}"></i>
	  Total visits <span class="busuanzi-value" id="busuanzi_value_site_pv"></span> times.
	</span>
{% endif %}