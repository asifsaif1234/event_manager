class EventsController < ApplicationController
  def index
    @events = [
      {
        id: "1984771",
        title: "Fællesspisning på ANKER",
        description: "Fællesspisning på ANKER i Sydhavnen. Menu for onsdag den 20. september: Hovedret: Gullasch med kartofler",
        image_link: "https://billetto.imgix.net/msss6nzshfr4seb5e55a834ao59q?w=1200&h=675&fit=crop&auto=compress%2Cformat&rect=40%2C0%2C1120%2C630&s=ac1de8bd49e5b65d14cfb8d3aeaabd74",
        start_date: "2026-09-30T16:00:00Z",
        location: "ANKER, Mozarts Pl. 1A, København",
        price: "125 DKK",
        category: "Food & Drink",
        likes: 0,
        dislikes: 0
      },
      {
        id: "1984770",
        title: "Anna Juul hos KFM",
        description: "Forfatterarrangement med Anna Juul, som vil fortælle om sin nye roman: Sød tøs",
        image_link: "https://billetto.imgix.net/avroql3n135e9bplyuq2nsqcsh0j?w=1200&h=675&fit=crop&auto=compress%2Cformat&rect=0%2C492%2C2400%2C1350&s=02f5a43c71679390398668db457d70af",
        start_date: "2026-10-08T16:30:00Z",
        location: "BOGhandleren Aarhus, Store Torv 5, Aarhus",
        price: "50 DKK",
        category: "Performing Arts",
        likes: 0,
        dislikes: 0
      },
      {
        id: "1984746",
        title: "IVOKE SUMMER EDITION 2,0",
        description: "En uformel aften for voksne mennesker, der savner mere ærlighed og nysgerrighed.",
        image_link: "https://images.unsplash.com/uploads/14121010130570e22bcdf/e1730efe?ixid=M3wzNDYzN3wwfDF8c2VhcmNofDd8fFN1bW1lcnxlbnwwfDB8fHwxNzg3NTc5NzIyfDA&ixlib=rb-4.1.0&auto=compress%2Cformat&fit=crop&h=675&rect=0%2C295%2C5665%2C3187&w=1200",
        start_date: "2026-09-03T17:00:00Z",
        location: "World of Wine, Byvej 55, Hvidovre",
        price: "275 DKK",
        category: "Health & Wellness",
        likes: 0,
        dislikes: 0
      },
      {
        id: "1984740",
        title: "Stauning Whiskysmagning",
        description: "Kom til Stauning Whiskysmagning torsdag den 3. december kl. 19.00.",
        image_link: "https://billetto.imgix.net/hi3p9iytm95s64o75jzhhdy6wp91?w=1200&h=675&fit=crop&auto=compress%2Cformat&rect=28%2C0%2C1612%2C907&s=2b5286c5b00e6a584aa9cd19ab8b18e1",
        start_date: "2026-12-03T18:00:00Z",
        location: "Farum Vin, Farum Bytorv 43, Farum",
        price: "199 DKK",
        category: "Food & Drink",
        likes: 0,
        dislikes: 0
      },
      {
        id: "1984735",
        title: "Klarsynsaften på Slot",
        description: "En hel unik muligt for at opleve Den Åndelige Verden på et Slot.",
        image_link: "https://billetto.imgix.net/pv1vmm39g2s4asomb9x7cpkn7nuu?w=1200&h=675&fit=crop&auto=compress%2Cformat&rect=0%2C56%2C1024%2C576&s=ce010e0b48eefe1764f4c589ee9c2ce5",
        start_date: "2026-10-27T18:00:00Z",
        location: "Harridslevgaard Slot, Assensvej 3, Bogense",
        price: "300 DKK",
        category: "Religion & Spirituality",
        likes: 0,
        dislikes: 0
      },
      {
        id: "1984723",
        title: "Efterårsferie på Middelaldercentret",
        description: "Træd ind i fortiden og oplev magi, handel og ridderturnering i efterårsferien! ⚔️🌟",
        image_link: "https://billetto.imgix.net/wtmymp3f4pvnsovleq6k47nsceu3?w=1200&h=675&fit=crop&auto=compress%2Cformat&rect=0%2C0%2C1600%2C900&s=a530f1d5c2a09acb22367355d343d6b4",
        start_date: "2026-10-12T08:00:00Z",
        location: "Middelaldercentret, Ved Hamborgskoven 2, Nykøbing Falster",
        price: "Free",
        category: "Community & Culture",
        likes: 0,
        dislikes: 0
      }
    ]
  end
end
